import AppKit
import Observation

@MainActor
@Observable
final class ReaderController {
    private(set) var presentationState: ReaderPresentationState = .hidden
    private(set) var currentSession: ReaderSession?
    private(set) var metrics: DisplayMetrics?
    private(set) var wordsPerMinute: Int

    @ObservationIgnored private let acquisition: TextAcquisitionCoordinator
    @ObservationIgnored private let tokenizer: RSVPTokenizer
    @ObservationIgnored private let settings: ReaderSettingsStore
    @ObservationIgnored private let displayResolver: DisplayResolver
    @ObservationIgnored private let panelController: ReaderPanelController
    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var keyboardMonitor: Any?
    @ObservationIgnored private var priorApplication: NSRunningApplication?

    init(
        acquisition: TextAcquisitionCoordinator,
        tokenizer: RSVPTokenizer,
        settings: ReaderSettingsStore,
        displayResolver: DisplayResolver,
        panelController: ReaderPanelController
    ) {
        self.acquisition = acquisition
        self.tokenizer = tokenizer
        self.settings = settings
        self.displayResolver = displayResolver
        self.panelController = panelController
        wordsPerMinute = settings.wordsPerMinute
    }

    var currentToken: RSVPToken? {
        guard let session = currentSession, session.tokens.indices.contains(session.index) else { return nil }
        return session.tokens[session.index]
    }

    var expandedWidth: CGFloat { metrics?.maximumSurfaceWidth ?? 600 }
    var closedSize: CGSize { metrics?.physicalNotchSize ?? CGSize(width: 185, height: 32) }
    var fallbackHiddenOffset: CGFloat {
        guard presentationState == .hidden || presentationState == .collapsing else { return 0 }
        return metrics?.hasPhysicalNotch == false ? -closedSize.height : 0
    }
    var sourceLabel: String {
        currentSession?.acquiredText.source == .accessibilitySelection ? "Selection" : "Clipboard"
    }
    var sourceIconName: String? {
        switch currentSession?.acquiredText.source {
        case .accessibilitySelection: "laptopcomputer"
        case .clipboard: "clipboard"
        case nil: nil
        }
    }

    func startFromCurrentContext() { start(with: acquisition.acquireCurrentText()) }
    func startFromClipboard() { start(with: acquisition.acquireClipboardOnly()) }

    private func start(with acquiredText: AcquiredText?) {
        cancelActive(clearSession: true)
        wordsPerMinute = settings.wordsPerMinute
        guard let metrics = displayResolver.resolve(originatingWindowFrame: acquiredText?.originatingWindowFrame) else { return }
        self.metrics = metrics

        guard let acquiredText else {
            priorApplication = NSWorkspace.shared.frontmostApplication
            presentationState = .hidden
            panelController.show(controller: self, metrics: metrics)
            playbackTask = Task { [weak self] in
                await Task.yield()
                guard !Task.isCancelled, let self else { return }
                self.presentationState = .message("Select or copy some text first")
                try? await Task.sleep(for: .milliseconds(1500))
                guard !Task.isCancelled else { return }
                await self.closeAnimated()
            }
            return
        }

        let tokens = tokenizer.tokenize(acquiredText.text)
        guard !tokens.isEmpty else { return }
        let session = ReaderSession(id: UUID(), acquiredText: acquiredText, tokens: tokens, index: 0)
        currentSession = session
        priorApplication = acquiredText.originatingApplication
        presentationState = .hidden
        panelController.show(controller: self, metrics: metrics)
        panelController.takeFocus()
        installKeyboardMonitor()
        beginPlayback(sessionID: session.id, delayForExpansion: true)
    }

    private func beginPlayback(sessionID: UUID, delayForExpansion: Bool) {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            if delayForExpansion {
                await Task.yield()
                guard !Task.isCancelled, let self, self.currentSession?.id == sessionID else { return }
                self.presentationState = .expanding
                try? await Task.sleep(for: ReaderAnimations.expansionDelay)
            }
            guard !Task.isCancelled, let self, self.currentSession?.id == sessionID else { return }
            self.presentationState = .playing

            while let token = self.currentToken, self.currentSession?.id == sessionID {
                let milliseconds = Double(60_000) / Double(self.wordsPerMinute) * token.delayMultiplier
                try? await Task.sleep(for: .milliseconds(Int64(milliseconds)))
                guard !Task.isCancelled, self.currentSession?.id == sessionID else { return }
                guard var session = self.currentSession else { return }
                if session.index == session.tokens.count - 1 {
                    try? await Task.sleep(for: ReaderAnimations.finalHold)
                    guard !Task.isCancelled, self.currentSession?.id == sessionID else { return }
                    await self.closeAnimated()
                    return
                }
                session.index += 1
                self.currentSession = session
            }
        }
    }

    func togglePause() {
        guard let session = currentSession else { return }
        switch presentationState {
        case .playing:
            playbackTask?.cancel()
            presentationState = .paused
        case .paused:
            beginPlayback(sessionID: session.id, delayForExpansion: false)
        default: break
        }
    }

    func changeSpeed(by amount: Int) {
        settings.setWPM(settings.wordsPerMinute + amount)
        wordsPerMinute = settings.wordsPerMinute
        if presentationState == .playing, let id = currentSession?.id {
            beginPlayback(sessionID: id, delayForExpansion: false)
        }
    }

    func step(by amount: Int) {
        guard presentationState == .paused, var session = currentSession else { return }
        session.index = min(max(session.index + amount, 0), session.tokens.count - 1)
        currentSession = session
    }

    func closeImmediately() {
        cancelActive(clearSession: true)
        panelController.hide()
        presentationState = .hidden
        restoreFocus()
    }

    private func closeAnimated() async {
        playbackTask = nil
        removeKeyboardMonitor()
        presentationState = .collapsing
        try? await Task.sleep(for: .milliseconds(220))
        panelController.hide()
        currentSession = nil
        presentationState = .hidden
        restoreFocus()
    }

    private func cancelActive(clearSession: Bool) {
        playbackTask?.cancel()
        playbackTask = nil
        removeKeyboardMonitor()
        if clearSession { currentSession = nil }
    }

    private func installKeyboardMonitor() {
        removeKeyboardMonitor()
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            switch event.keyCode {
            case 49: self.togglePause()
            case 53: self.closeImmediately()
            case 126: self.changeSpeed(by: 25)
            case 125: self.changeSpeed(by: -25)
            case 123: self.step(by: -1)
            case 124: self.step(by: 1)
            default: return event
            }
            return nil
        }
    }

    private func removeKeyboardMonitor() {
        if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }
        keyboardMonitor = nil
    }

    private func restoreFocus() {
        guard let priorApplication, !priorApplication.isTerminated else { return }
        let readerApplication = NSRunningApplication.current
        NSApp.yieldActivation(to: priorApplication)
        _ = priorApplication.activate(from: readerApplication, options: [])
        self.priorApplication = nil
    }
}

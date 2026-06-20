import AppKit
import OSLog

@MainActor
final class TextAcquisitionCoordinator {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "RSVPIsland",
        category: "TextAcquisition"
    )

    private let accessibility: AccessibilityTextProviding
    private let clipboard: ClipboardTextProviding

    init(accessibility: AccessibilityTextProviding, clipboard: ClipboardTextProviding) {
        self.accessibility = accessibility
        self.clipboard = clipboard
    }

    func acquireCurrentText() -> AcquiredText? {
        let application = NSWorkspace.shared.frontmostApplication
        if let selection = accessibility.currentSelection() {
            Self.logger.info("Using Accessibility selection")
            return AcquiredText(
                text: selection.text,
                source: .accessibilitySelection,
                originatingApplication: application,
                originatingWindowFrame: selection.focusedWindowFrame
            )
        }
        Self.logger.info("Accessibility selection unavailable; trying clipboard fallback")
        return acquiredClipboard(originatingApplication: application)
    }

    func acquireClipboardOnly() -> AcquiredText? {
        acquiredClipboard(originatingApplication: NSWorkspace.shared.frontmostApplication)
    }

    private func acquiredClipboard(originatingApplication: NSRunningApplication?) -> AcquiredText? {
        guard let text = clipboard.currentPlainText() else {
            Self.logger.info("Clipboard fallback has no plain text")
            return nil
        }
        Self.logger.info("Using clipboard fallback with \(text.count) characters")
        return AcquiredText(
            text: text,
            source: .clipboard,
            originatingApplication: originatingApplication,
            originatingWindowFrame: nil
        )
    }
}

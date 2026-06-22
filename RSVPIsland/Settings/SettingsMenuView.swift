import AppKit
import KeyboardShortcuts
import SwiftUI

struct SettingsMenuView: View {
    @Bindable var settings: ReaderSettingsStore
    @Bindable var loginItem: LoginItemController
    let accessibility: AccessibilityTextProvider
    let reader: ReaderController

    var body: some View {
        SettingsMenuContent(
            wordsPerMinute: Binding(
                get: { settings.wordsPerMinute },
                set: { settings.setWPM($0) }
            ),
            firstWordPauseSeconds: Binding(
                get: { settings.firstWordPauseSeconds },
                set: { settings.setFirstWordPause($0) }
            ),
            sentenceSkipWindowSeconds: Binding(
                get: { settings.sentenceSkipWindowSeconds },
                set: { settings.setSentenceSkipWindow($0) }
            ),
            launchAtLogin: Binding(
                get: { loginItem.isEnabled },
                set: { enabled in
                    settings.launchAtLogin = enabled
                    settings.loginBehaviorChanged = true
                    loginItem.setEnabled(enabled)
                }
            ),
            accessibilityEnabled: accessibility.isTrusted,
            loginError: loginItem.errorMessage,
            showsShortcutRecorder: true,
            usesStaticControls: false,
            requestAccess: { accessibility.requestTrustPrompt() },
            readClipboard: { reader.startFromClipboard() },
            showAbout: showAbout,
            quit: { NSApp.terminate(nil) }
        )
        .task {
            while !Task.isCancelled {
                accessibility.refreshTrustStatus()
                do {
                    try await Task.sleep(for: .milliseconds(500))
                } catch {
                    return
                }
            }
        }
    }

    private func showAbout() {
        let icon = NSApp.applicationIconImage.copy() as! NSImage
        icon.size = NSSize(width: 256, height: 256)
        NSApp.orderFrontStandardAboutPanel(options: [.applicationIcon: icon])
        NSApp.activate()
    }
}

struct SettingsMenuContent: View {
    @Binding var wordsPerMinute: Int
    @Binding var firstWordPauseSeconds: Double
    @Binding var sentenceSkipWindowSeconds: Double
    @Binding var launchAtLogin: Bool
    let accessibilityEnabled: Bool
    let loginError: String?
    let showsShortcutRecorder: Bool
    let usesStaticControls: Bool
    let requestAccess: () -> Void
    let readClipboard: () -> Void
    let showAbout: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RSVP Island").font(.headline)

            HStack {
                Text("Speed")
                if usesStaticControls {
                    StaticSlider(position: Double(wordsPerMinute - 100) / 900)
                } else {
                    Slider(
                        value: Binding(
                            get: { Double(wordsPerMinute) },
                            set: { wordsPerMinute = Int($0.rounded()) }
                        ),
                        in: 100...1_000,
                        step: 25
                    )
                }
                Text("\(wordsPerMinute) WPM")
                    .monospacedDigit()
                    .frame(width: 76, alignment: .trailing)
            }

            HStack {
                Text("First word pause")
                if usesStaticControls {
                    StaticSlider(position: firstWordPauseSeconds / 3)
                } else {
                    Slider(
                        value: Binding(
                            get: { firstWordPauseSeconds },
                            set: { firstWordPauseSeconds = $0 }
                        ),
                        in: 0...3,
                        step: 0.1
                    )
                }
                Text(firstWordPauseSeconds == 0
                    ? "Off"
                    : String(format: "%.1f s", firstWordPauseSeconds))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }

            HStack {
                Text("Sentence skip window")
                if usesStaticControls {
                    StaticSlider(position: sentenceSkipWindowSeconds / 3)
                } else {
                    Slider(
                        value: Binding(
                            get: { sentenceSkipWindowSeconds },
                            set: { sentenceSkipWindowSeconds = $0 }
                        ),
                        in: 0...3,
                        step: 0.1
                    )
                }
                Text(sentenceSkipWindowSeconds == 0
                    ? "Off"
                    : String(format: "%.1f s", sentenceSkipWindowSeconds))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }

            HStack {
                Text("Shortcut")
                Spacer()
                if showsShortcutRecorder {
                    KeyboardShortcuts.Recorder(for: .startReading)
                } else {
                    Text("⌃⌥R")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
            }

            if usesStaticControls {
                HStack {
                    Text("Launch at Login")
                    Spacer()
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: 30, height: 18)
                        .overlay(alignment: .leading) {
                            Circle().fill(.white.opacity(0.8)).padding(2)
                        }
                }
            } else {
                Toggle("Launch at Login", isOn: $launchAtLogin)
            }
            if let error = loginError {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            HStack {
                Label(
                    accessibilityEnabled ? "Accessibility enabled" : "Accessibility not enabled",
                    systemImage: accessibilityEnabled ? "checkmark.circle" : "exclamationmark.circle"
                )
                Spacer()
                if !accessibilityEnabled {
                    Button("Request Access", action: requestAccess)
                }
            }

            Button("Read Clipboard Now", action: readClipboard)
                .keyboardShortcut(.return, modifiers: [])

            Divider()
            HStack {
                Button("About", action: showAbout)
                Spacer()
                Button("Quit", action: quit)
            }
        }
        .padding(16)
        .frame(width: 390)
    }
}

private struct StaticSlider: View {
    let position: Double

    var body: some View {
        GeometryReader { proxy in
            let diameter: CGFloat = 14
            let availableWidth = max(proxy.size.width - diameter, 0)
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary).frame(height: 4)
                Capsule().fill(.blue).frame(width: availableWidth * CGFloat(position) + diameter / 2, height: 4)
                Circle()
                    .fill(.white)
                    .shadow(radius: 1)
                    .frame(width: diameter, height: diameter)
                    .offset(x: availableWidth * CGFloat(position))
            }
            .frame(maxHeight: .infinity)
        }
        .frame(minWidth: 80, maxWidth: .infinity)
        .frame(height: 18)
    }
}

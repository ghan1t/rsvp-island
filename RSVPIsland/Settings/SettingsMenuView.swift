import AppKit
import KeyboardShortcuts
import SwiftUI

struct SettingsMenuView: View {
    @Bindable var settings: ReaderSettingsStore
    @Bindable var loginItem: LoginItemController
    let accessibility: AccessibilityTextProvider
    let reader: ReaderController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RSVP Island").font(.headline)

            HStack {
                Text("Speed")
                Slider(
                    value: Binding(
                        get: { Double(settings.wordsPerMinute) },
                        set: { settings.setWPM(Int($0.rounded())) }
                    ),
                    in: 100...1_000,
                    step: 25
                )
                Text("\(settings.wordsPerMinute) WPM")
                    .monospacedDigit()
                    .frame(width: 76, alignment: .trailing)
            }

            HStack {
                Text("First word pause")
                Slider(
                    value: Binding(
                        get: { settings.firstWordPauseSeconds },
                        set: { settings.setFirstWordPause($0) }
                    ),
                    in: 0...3,
                    step: 0.1
                )
                Text(settings.firstWordPauseSeconds == 0
                    ? "Off"
                    : String(format: "%.1f s", settings.firstWordPauseSeconds))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }

            HStack {
                Text("Sentence skip window")
                Slider(
                    value: Binding(
                        get: { settings.sentenceSkipWindowSeconds },
                        set: { settings.setSentenceSkipWindow($0) }
                    ),
                    in: 0...3,
                    step: 0.1
                )
                Text(settings.sentenceSkipWindowSeconds == 0
                    ? "Off"
                    : String(format: "%.1f s", settings.sentenceSkipWindowSeconds))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }

            HStack {
                Text("Shortcut")
                Spacer()
                KeyboardShortcuts.Recorder(for: .startReading)
            }

            Toggle("Launch at Login", isOn: Binding(
                get: { loginItem.isEnabled },
                set: { enabled in
                    settings.launchAtLogin = enabled
                    settings.loginBehaviorChanged = true
                    loginItem.setEnabled(enabled)
                }
            ))
            if let error = loginItem.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            HStack {
                Label(
                    accessibility.isTrusted ? "Accessibility enabled" : "Accessibility not enabled",
                    systemImage: accessibility.isTrusted ? "checkmark.circle" : "exclamationmark.circle"
                )
                Spacer()
                if !accessibility.isTrusted {
                    Button("Request Access") { accessibility.requestTrustPrompt() }
                }
            }

            Button("Read Clipboard Now") { reader.startFromClipboard() }
                .keyboardShortcut(.return, modifiers: [])

            Divider()
            HStack {
                Button("About") {
                    let icon = NSApp.applicationIconImage.copy() as! NSImage
                    icon.size = NSSize(width: 256, height: 256)
                    NSApp.orderFrontStandardAboutPanel(options: [.applicationIcon: icon])
                    NSApp.activate()
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 390)
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
}

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
                Button("Request Access") { accessibility.requestTrustPrompt() }
            }

            Button("Open Accessibility Settings") {
                let path = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                if let url = URL(string: path) { NSWorkspace.shared.open(url) }
            }
            Button("Read Clipboard Now") { reader.startFromClipboard() }
                .keyboardShortcut(.return, modifiers: [])

            Divider()
            HStack {
                Button("About") {
                    NSApp.orderFrontStandardAboutPanel(nil)
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

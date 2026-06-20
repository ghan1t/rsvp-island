import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let container = AppContainer.shared
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        KeyboardShortcuts.onKeyUp(for: .startReading) { [weak self] in
            self?.container.reader.startFromCurrentContext()
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AppContainer.shared.panel.handleDisplayChange(controller: AppContainer.shared.reader)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.reader.closeImmediately()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
    }
}

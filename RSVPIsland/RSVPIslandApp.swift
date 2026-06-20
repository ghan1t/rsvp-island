import SwiftUI

@main
struct RSVPIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            SettingsMenuView(
                settings: AppContainer.shared.settings,
                loginItem: AppContainer.shared.loginItem,
                accessibility: AppContainer.shared.accessibility,
                reader: AppContainer.shared.reader
            )
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}

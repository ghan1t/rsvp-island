import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let settings: ReaderSettingsStore
    let accessibility: AccessibilityTextProvider
    let loginItem: LoginItemController
    let reader: ReaderController
    let panel: ReaderPanelController

    private init() {
        let settings = ReaderSettingsStore()
        let accessibility = AccessibilityTextProvider()
        let clipboard = ClipboardTextProvider()
        let acquisition = TextAcquisitionCoordinator(accessibility: accessibility, clipboard: clipboard)
        let panel = ReaderPanelController()
        self.settings = settings
        self.accessibility = accessibility
        self.loginItem = LoginItemController()
        self.panel = panel
        self.reader = ReaderController(
            acquisition: acquisition,
            tokenizer: RSVPTokenizer(),
            settings: settings,
            displayResolver: DisplayResolver(),
            panelController: panel
        )
    }
}

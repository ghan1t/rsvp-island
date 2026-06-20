import Observation
import ServiceManagement

@MainActor
@Observable
final class LoginItemController {
    private(set) var isEnabled = false
    private(set) var errorMessage: String?

    init() { refreshStatus() }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshStatus()
    }

    func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}

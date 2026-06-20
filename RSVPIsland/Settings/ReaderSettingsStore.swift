import Foundation
import Observation

@MainActor
@Observable
final class ReaderSettingsStore {
    private enum Key {
        static let wordsPerMinute = "wordsPerMinute"
        static let launchAtLogin = "launchAtLogin"
        static let onboardingShown = "onboardingShown"
        static let loginBehaviorChanged = "loginBehaviorChanged"
    }

    private let defaults: UserDefaults

    var wordsPerMinute: Int {
        didSet {
            let clamped = Self.clamp(wordsPerMinute)
            if wordsPerMinute != clamped {
                wordsPerMinute = clamped
            } else {
                defaults.set(wordsPerMinute, forKey: Key.wordsPerMinute)
            }
        }
    }

    var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin) }
    }

    var onboardingShown: Bool {
        didSet { defaults.set(onboardingShown, forKey: Key.onboardingShown) }
    }

    var loginBehaviorChanged: Bool {
        didSet { defaults.set(loginBehaviorChanged, forKey: Key.loginBehaviorChanged) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        wordsPerMinute = defaults.object(forKey: Key.wordsPerMinute) == nil
            ? 350 : Self.clamp(defaults.integer(forKey: Key.wordsPerMinute))
        // Development default: login launch is opt-in, never auto-registered.
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) == nil
            ? false : defaults.bool(forKey: Key.launchAtLogin)
        onboardingShown = defaults.bool(forKey: Key.onboardingShown)
        loginBehaviorChanged = defaults.bool(forKey: Key.loginBehaviorChanged)
    }

    func increaseWPM() { setWPM(wordsPerMinute + 25) }
    func decreaseWPM() { setWPM(wordsPerMinute - 25) }
    func setWPM(_ value: Int) { wordsPerMinute = Self.clamp(value) }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 100), 1_000)
    }
}

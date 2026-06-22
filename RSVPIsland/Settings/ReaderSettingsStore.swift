import Foundation
import Observation

@MainActor
@Observable
final class ReaderSettingsStore {
    private enum Key {
        static let wordsPerMinute = "wordsPerMinute"
        static let firstWordPauseSeconds = "firstWordPauseSeconds"
        static let sentenceSkipWindowSeconds = "sentenceSkipWindowSeconds"
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

    var firstWordPauseSeconds: Double {
        didSet {
            let clamped = Self.clampSeconds(firstWordPauseSeconds)
            if firstWordPauseSeconds != clamped {
                firstWordPauseSeconds = clamped
            } else {
                defaults.set(firstWordPauseSeconds, forKey: Key.firstWordPauseSeconds)
            }
        }
    }

    var sentenceSkipWindowSeconds: Double {
        didSet {
            let clamped = Self.clampSeconds(sentenceSkipWindowSeconds)
            if sentenceSkipWindowSeconds != clamped {
                sentenceSkipWindowSeconds = clamped
            } else {
                defaults.set(sentenceSkipWindowSeconds, forKey: Key.sentenceSkipWindowSeconds)
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
        firstWordPauseSeconds = defaults.object(forKey: Key.firstWordPauseSeconds) == nil
            ? 1.0 : Self.clampSeconds(defaults.double(forKey: Key.firstWordPauseSeconds))
        sentenceSkipWindowSeconds = defaults.object(forKey: Key.sentenceSkipWindowSeconds) == nil
            ? 0.5 : Self.clampSeconds(defaults.double(forKey: Key.sentenceSkipWindowSeconds))
        // Development default: login launch is opt-in, never auto-registered.
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) == nil
            ? false : defaults.bool(forKey: Key.launchAtLogin)
        onboardingShown = defaults.bool(forKey: Key.onboardingShown)
        loginBehaviorChanged = defaults.bool(forKey: Key.loginBehaviorChanged)
    }

    func increaseWPM() { setWPM(wordsPerMinute + 25) }
    func decreaseWPM() { setWPM(wordsPerMinute - 25) }
    func setWPM(_ value: Int) { wordsPerMinute = Self.clamp(value) }
    func setFirstWordPause(_ value: Double) {
        firstWordPauseSeconds = Self.clampSeconds(value)
    }
    func setSentenceSkipWindow(_ value: Double) {
        sentenceSkipWindowSeconds = Self.clampSeconds(value)
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 100), 1_000)
    }

    private static func clampSeconds(_ value: Double) -> Double {
        min(max(value, 0), 3)
    }
}

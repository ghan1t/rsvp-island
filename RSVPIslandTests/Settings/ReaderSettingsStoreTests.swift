import XCTest
@testable import RSVPIsland

@MainActor
final class ReaderSettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = makeDefaults()
        let store = ReaderSettingsStore(defaults: defaults)
        XCTAssertEqual(store.wordsPerMinute, 350)
        XCTAssertEqual(store.firstWordPauseSeconds, 1)
        XCTAssertEqual(store.sentenceSkipWindowSeconds, 0.5)
        XCTAssertFalse(store.launchAtLogin)
    }

    func testWPMClampingAndSteps() {
        let defaults = makeDefaults()
        let store = ReaderSettingsStore(defaults: defaults)
        store.setWPM(50)
        XCTAssertEqual(store.wordsPerMinute, 100)
        store.setWPM(2_000)
        XCTAssertEqual(store.wordsPerMinute, 1_000)
        store.decreaseWPM()
        XCTAssertEqual(store.wordsPerMinute, 975)
        store.increaseWPM()
        XCTAssertEqual(store.wordsPerMinute, 1_000)
    }

    func testValuesPersist() {
        let defaults = makeDefaults()
        let store = ReaderSettingsStore(defaults: defaults)
        store.setWPM(425)
        store.setFirstWordPause(2.5)
        store.setSentenceSkipWindow(1.2)
        store.launchAtLogin = true
        let reloaded = ReaderSettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.wordsPerMinute, 425)
        XCTAssertEqual(reloaded.firstWordPauseSeconds, 2.5)
        XCTAssertEqual(reloaded.sentenceSkipWindowSeconds, 1.2)
        XCTAssertTrue(reloaded.launchAtLogin)
    }

    func testFirstWordPauseClamping() {
        let store = ReaderSettingsStore(defaults: makeDefaults())
        store.setFirstWordPause(-1)
        XCTAssertEqual(store.firstWordPauseSeconds, 0)
        store.setFirstWordPause(10)
        XCTAssertEqual(store.firstWordPauseSeconds, 3)
    }

    func testSentenceSkipWindowClamping() {
        let store = ReaderSettingsStore(defaults: makeDefaults())
        store.setSentenceSkipWindow(-1)
        XCTAssertEqual(store.sentenceSkipWindowSeconds, 0)
        store.setSentenceSkipWindow(10)
        XCTAssertEqual(store.sentenceSkipWindowSeconds, 3)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReaderSettingsStoreTests.\(UUID().uuidString)")!
    }
}

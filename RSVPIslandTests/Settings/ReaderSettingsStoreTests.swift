import XCTest
@testable import RSVPIsland

@MainActor
final class ReaderSettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = makeDefaults()
        let store = ReaderSettingsStore(defaults: defaults)
        XCTAssertEqual(store.wordsPerMinute, 350)
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
        store.launchAtLogin = true
        let reloaded = ReaderSettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.wordsPerMinute, 425)
        XCTAssertTrue(reloaded.launchAtLogin)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReaderSettingsStoreTests.\(UUID().uuidString)")!
    }
}

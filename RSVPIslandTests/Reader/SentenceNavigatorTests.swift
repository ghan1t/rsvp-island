import XCTest
@testable import RSVPIsland

final class SentenceNavigatorTests: XCTestCase {
    private let tokenizer = RSVPTokenizer()
    private let navigator = SentenceNavigator()

    func testBackwardRestartsCurrentSentenceOutsideSkipWindow() {
        let tokens = tokenizer.tokenize("One ends. This sentence has enough words to move well beyond the window.")
        XCTAssertEqual(destination(from: 10, direction: .backward, tokens: tokens, wpm: 120), 2)
    }

    func testBackwardSkipsPreviousSentenceInsideSkipWindow() {
        let tokens = tokenizer.tokenize("One ends. This sentence continues.")
        XCTAssertEqual(destination(from: 3, direction: .backward, tokens: tokens, wpm: 120), 0)
    }

    func testSkipWindowScalesWithReadingSpeed() {
        let tokens = tokenizer.tokenize("One ends. This sentence has enough words to move beyond a slow reading window.")
        XCTAssertEqual(destination(from: 10, direction: .backward, tokens: tokens, wpm: 120), 2)
        XCTAssertEqual(destination(from: 10, direction: .backward, tokens: tokens, wpm: 1_000), 0)
    }

    func testConfiguredSkipWindowChangesDestination() {
        let tokens = tokenizer.tokenize("One ends. This sentence has enough words to test the configurable window.")
        XCTAssertEqual(destination(from: 6, direction: .backward, tokens: tokens, wpm: 120, window: 0), 2)
        XCTAssertEqual(destination(from: 6, direction: .backward, tokens: tokens, wpm: 120, window: 3), 0)
    }

    func testForwardStartsNextSentenceOutsideSkipWindow() {
        let tokens = tokenizer.tokenize("This sentence has enough words before it finally ends. Next ends.")
        XCTAssertEqual(destination(from: 1, direction: .forward, tokens: tokens, wpm: 120), 9)
    }

    func testForwardStartsNextSentenceInsideSkipWindow() {
        let tokens = tokenizer.tokenize("This sentence ends soon. Next one ends.")
        XCTAssertEqual(destination(from: 2, direction: .forward, tokens: tokens, wpm: 120), 4)
    }

    func testForwardStaysAtEndOfFinalSentence() {
        let tokens = tokenizer.tokenize("Only one sentence ends.")
        XCTAssertEqual(destination(from: 1, direction: .forward, tokens: tokens, wpm: 120), 3)
    }

    private func destination(
        from index: Int,
        direction: SentenceNavigator.Direction,
        tokens: [RSVPToken],
        wpm: Int,
        window: Double = 2
    ) -> Int {
        navigator.destination(
            from: index,
            direction: direction,
            tokens: tokens,
            wordsPerMinute: wpm,
            skipWindowSeconds: window
        )
    }
}

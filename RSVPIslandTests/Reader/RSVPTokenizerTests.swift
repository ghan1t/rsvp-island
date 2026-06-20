import XCTest
@testable import RSVPIsland

final class RSVPTokenizerTests: XCTestCase {
    private let tokenizer = RSVPTokenizer()

    func testEmptyAndWhitespaceOnlyInput() {
        XCTAssertEqual(tokenizer.tokenize(""), [])
        XCTAssertEqual(tokenizer.tokenize(" \t\n "), [])
    }

    func testOneCharacterAndEveryORPBoundary() throws {
        let cases: [(String, Character)] = [
            ("a", "a"), ("ab", "b"), ("abcde", "b"),
            ("abcdef", "c"), ("abcdefghi", "c"),
            ("abcdefghij", "d"), ("abcdefghijklm", "d"),
            ("abcdefghijklmn", "e")
        ]
        for (word, expectedPivot) in cases {
            XCTAssertEqual(try XCTUnwrap(tokenizer.tokenize(word).first).pivot, expectedPivot, word)
        }
    }

    func testQuotesDoNotShiftPivotAndArePreserved() throws {
        let token = try XCTUnwrap(tokenizer.tokenize("“hello!”").first)
        XCTAssertEqual(token.original, "“hello!”")
        XCTAssertEqual(token.prefix, "“h")
        XCTAssertEqual(token.pivot, "e")
        XCTAssertEqual(token.suffix, "llo!”")
        XCTAssertEqual(token.delayMultiplier, 2)
    }

    func testApostropheAndHyphenRemainInOriginalWord() {
        XCTAssertEqual(tokenizer.tokenize("don't mother-in-law").map(\.original), ["don't", "mother-in-law"])
    }

    func testComposedAndDecomposedAccentsAreCharacters() throws {
        XCTAssertEqual(try XCTUnwrap(tokenizer.tokenize("école").first).pivot, "c")
        XCTAssertEqual(try XCTUnwrap(tokenizer.tokenize("e\u{301}cole").first).pivot, "c")
    }

    func testCyrillicText() throws {
        XCTAssertEqual(try XCTUnwrap(tokenizer.tokenize("привет").first).pivot, "и")
    }

    func testEmojiOnlyTokenHasNoPivot() throws {
        let token = try XCTUnwrap(tokenizer.tokenize("👨‍👩‍👧‍👦").first)
        XCTAssertNil(token.pivot)
        XCTAssertEqual(token.prefix, token.original)
        XCTAssertEqual(token.suffix, "")
    }

    func testPunctuationMultipliers() {
        let tokens = tokenizer.tokenize("plain word, colon: semi; end. question? bang! ellipsis…")
        XCTAssertEqual(tokens.map(\.delayMultiplier), [1, 1.5, 1.5, 1.5, 2, 2, 2, 2])
    }

    func testCRLFAndParagraphBreak() {
        let tokens = tokenizer.tokenize("first\r\nline\r\n\r\nnext")
        XCTAssertEqual(tokens.map(\.original), ["first", "line", "next"])
        XCTAssertEqual(tokens.map(\.delayMultiplier), [1, 2.5, 1])
    }

    func testSentencePunctuationWinsBeforeParagraphMaximum() throws {
        let token = try XCTUnwrap(tokenizer.tokenize("Done!\n\nNext").first)
        XCTAssertEqual(token.delayMultiplier, 2.5)
    }
}

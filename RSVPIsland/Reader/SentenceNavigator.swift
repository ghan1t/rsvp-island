import Foundation

struct SentenceNavigator: Sendable {
    func destination(
        from index: Int,
        direction: Direction,
        tokens: [RSVPToken],
        wordsPerMinute: Int,
        skipWindowSeconds: Double
    ) -> Int {
        guard !tokens.isEmpty else { return 0 }
        let index = min(max(index, 0), tokens.count - 1)
        // Convert the configured time window to the number of words read at the
        // active speed. Keep one boundary word so repeated presses still advance.
        let threshold = max(1, Int(ceil(Double(wordsPerMinute) / 60 * skipWindowSeconds)))
        let start = sentenceStart(containing: index, tokens: tokens)
        let end = sentenceEnd(containing: index, tokens: tokens)

        switch direction {
        case .backward:
            guard index - start < threshold, start > 0 else { return start }
            return sentenceStart(containing: start - 1, tokens: tokens)
        case .forward:
            // Forward navigation starts the next sentence. Landing on the current
            // sentence's final word makes the reader pause before the actual skip.
            guard end < tokens.count - 1 else { return end }
            return end + 1
        }
    }

    enum Direction: Sendable {
        case backward
        case forward
    }

    private func sentenceStart(containing index: Int, tokens: [RSVPToken]) -> Int {
        guard index > 0 else { return 0 }
        for candidate in stride(from: index - 1, through: 0, by: -1) {
            if isSentenceEnd(tokens[candidate]) { return candidate + 1 }
        }
        return 0
    }

    private func sentenceEnd(containing index: Int, tokens: [RSVPToken]) -> Int {
        for candidate in index..<tokens.count where isSentenceEnd(tokens[candidate]) {
            return candidate
        }
        return tokens.count - 1
    }

    private func isSentenceEnd(_ token: RSVPToken) -> Bool {
        // Includes paragraph breaks, which the tokenizer marks with 2.5.
        token.delayMultiplier >= 2
    }
}

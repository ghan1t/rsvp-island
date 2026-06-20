import Foundation

struct RSVPTokenizer: Sendable {
    func tokenize(_ input: String) -> [RSVPToken] {
        let normalized = input
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let range = NSRange(normalized.startIndex..., in: normalized)
        let matches = Self.nonWhitespace.matches(in: normalized, range: range)

        return matches.enumerated().compactMap { offset, match in
            guard let tokenRange = Range(match.range, in: normalized) else { return nil }
            let original = String(normalized[tokenRange])
            let paragraphBreak: Bool

            if offset + 1 < matches.count,
               let nextRange = Range(matches[offset + 1].range, in: normalized) {
                paragraphBreak = normalized[tokenRange.upperBound..<nextRange.lowerBound]
                    .filter { $0 == "\n" }.count >= 2
            } else {
                paragraphBreak = false
            }

            return makeToken(original, paragraphBreak: paragraphBreak)
        }
    }

    private func makeToken(_ original: String, paragraphBreak: Bool) -> RSVPToken {
        let characters = Array(original)
        let readablePositions = characters.indices.filter { characterIsReadable(characters[$0]) }
        let baseMultiplier = punctuationMultiplier(for: characters)
        let multiplier = paragraphBreak ? max(baseMultiplier, 2.5) : baseMultiplier

        guard !readablePositions.isEmpty else {
            return RSVPToken(
                original: original,
                prefix: original,
                pivot: nil,
                suffix: "",
                delayMultiplier: multiplier
            )
        }

        let readablePivot: Int
        switch readablePositions.count {
        case 1: readablePivot = 0
        case 2...5: readablePivot = 1
        case 6...9: readablePivot = 2
        case 10...13: readablePivot = 3
        default: readablePivot = 4
        }
        let pivotPosition = readablePositions[min(readablePivot, readablePositions.count - 1)]

        return RSVPToken(
            original: original,
            prefix: String(characters[..<pivotPosition]),
            pivot: characters[pivotPosition],
            suffix: String(characters[(pivotPosition + 1)...]),
            delayMultiplier: multiplier
        )
    }

    private func characterIsReadable(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            switch scalar.properties.generalCategory {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter,
                 .modifierLetter, .otherLetter, .decimalNumber:
                true
            default:
                false
            }
        }
    }

    private func punctuationMultiplier(for characters: [Character]) -> Double {
        let ignoredClosers: Set<Character> = ["\"", "'", "’", "”", ")", "]", "}", "»"]
        guard let trailing = characters.reversed().first(where: { !ignoredClosers.contains($0) }) else {
            return 1
        }
        if [".", "?", "!", "…"].contains(trailing) { return 2 }
        if [",", ":", ";"].contains(trailing) { return 1.5 }
        return 1
    }

    private static let nonWhitespace = try! NSRegularExpression(pattern: #"\S+"#)
}

import AppKit

enum TextSource: Equatable {
    case accessibilitySelection
    case clipboard
}

@MainActor
struct AcquiredText {
    let text: String
    let source: TextSource
    let originatingApplication: NSRunningApplication?
    let originatingWindowFrame: CGRect?
}

import AppKit

@MainActor
protocol ClipboardTextProviding {
    func currentPlainText() -> String?
}

@MainActor
final class ClipboardTextProvider: ClipboardTextProviding {
    func currentPlainText() -> String? {
        guard let value = NSPasteboard.general.string(forType: .string) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

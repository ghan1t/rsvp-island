import Foundation

@MainActor
struct ReaderSession {
    let id: UUID
    let acquiredText: AcquiredText
    let tokens: [RSVPToken]
    var index: Int
}

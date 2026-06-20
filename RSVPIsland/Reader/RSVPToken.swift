struct RSVPToken: Equatable, Sendable {
    let original: String
    let prefix: String
    let pivot: Character?
    let suffix: String
    let delayMultiplier: Double
}

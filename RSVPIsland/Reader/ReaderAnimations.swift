import SwiftUI

enum ReaderAnimations {
    static let expand = Animation.spring(response: 0.42, dampingFraction: 0.82)
    static let collapse = Animation.spring(response: 0.48, dampingFraction: 0.88)
    static let expansionDelay: Duration = .milliseconds(300)
    static let finalHold: Duration = .milliseconds(500)
}

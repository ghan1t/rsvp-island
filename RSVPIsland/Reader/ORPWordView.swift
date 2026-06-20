import SwiftUI

struct ORPWordView: View {
    let token: RSVPToken

    var body: some View {
        if let pivot = token.pivot {
            HStack(spacing: 0) {
                Text(token.prefix)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(String(pivot)).foregroundStyle(.red)
                Text(token.suffix)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 34, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
        } else {
            Text(token.original)
                .font(.system(size: 34, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.35)
        }
    }
}

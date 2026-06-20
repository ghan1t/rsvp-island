import SwiftUI

struct ReaderRootView: View {
    @Bindable var controller: ReaderController

    private var isExpanded: Bool {
        switch controller.presentationState {
        case .hidden, .collapsing: false
        default: true
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: isExpanded ? 20 : 12,
                bottomTrailingRadius: isExpanded ? 20 : 12,
                topTrailingRadius: 0
            )
            .fill(.black)
            .frame(
                width: isExpanded ? controller.expandedWidth : controller.closedSize.width,
                height: isExpanded ? 150 : controller.closedSize.height
            )
            .offset(y: controller.fallbackHiddenOffset)
            .overlay(alignment: .center) {
                content
                    .frame(width: max(controller.expandedWidth - 56, 100))
                    .offset(y: isExpanded ? 12 : 0)
                    .opacity(isExpanded ? 1 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                Text("\(controller.wordsPerMinute) WPM")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
                    .opacity(isExpanded ? 1 : 0)
            }
            .overlay(alignment: .bottomLeading) {
                if let sourceIconName = controller.sourceIconName {
                    Image(systemName: sourceIconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.leading, 12)
                        .padding(.bottom, 8)
                        .opacity(isExpanded ? 1 : 0)
                }
            }
            .animation(
                controller.presentationState == .collapsing
                    ? ReaderAnimations.collapse : ReaderAnimations.expand,
                value: isExpanded
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var content: some View {
        switch controller.presentationState {
        case .message(let message):
            Text(message).foregroundStyle(.white).font(.headline)
        case .expanding:
            Text(controller.sourceLabel)
                .foregroundStyle(.secondary)
                .font(.caption)
        case .playing, .paused:
            if let token = controller.currentToken {
                ORPWordView(token: token)
            }
        default:
            EmptyView()
        }
    }
}

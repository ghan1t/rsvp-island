import SwiftUI

struct ReaderRootView: View {
    @Bindable var controller: ReaderController

    var body: some View {
        ReaderSurfaceView(state: ReaderSurfaceState(controller: controller))
    }
}

struct ReaderSurfaceState {
    let presentationState: ReaderPresentationState
    let token: RSVPToken?
    let wordsPerMinute: Int
    let expandedWidth: CGFloat
    let closedSize: CGSize
    let fallbackHiddenOffset: CGFloat
    let sourceLabel: String
    let sourceIconName: String?
    let expansionProgressOverride: CGFloat?

    init(
        presentationState: ReaderPresentationState,
        token: RSVPToken?,
        wordsPerMinute: Int,
        expandedWidth: CGFloat,
        closedSize: CGSize,
        fallbackHiddenOffset: CGFloat,
        sourceLabel: String,
        sourceIconName: String?,
        expansionProgressOverride: CGFloat? = nil
    ) {
        self.presentationState = presentationState
        self.token = token
        self.wordsPerMinute = wordsPerMinute
        self.expandedWidth = expandedWidth
        self.closedSize = closedSize
        self.fallbackHiddenOffset = fallbackHiddenOffset
        self.sourceLabel = sourceLabel
        self.sourceIconName = sourceIconName
        self.expansionProgressOverride = expansionProgressOverride
    }

    @MainActor
    init(controller: ReaderController) {
        presentationState = controller.presentationState
        token = controller.currentToken
        wordsPerMinute = controller.wordsPerMinute
        expandedWidth = controller.expandedWidth
        closedSize = controller.closedSize
        fallbackHiddenOffset = controller.fallbackHiddenOffset
        sourceLabel = controller.sourceLabel
        sourceIconName = controller.sourceIconName
        expansionProgressOverride = nil
    }
}

struct ReaderSurfaceView: View {
    let state: ReaderSurfaceState

    private var isExpanded: Bool {
        switch state.presentationState {
        case .hidden, .collapsing: false
        default: true
        }
    }

    private var expansionProgress: CGFloat {
        state.expansionProgressOverride ?? (isExpanded ? 1 : 0)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12 + 8 * expansionProgress,
                bottomTrailingRadius: 12 + 8 * expansionProgress,
                topTrailingRadius: 0
            )
            .fill(.black)
            .frame(
                width: state.closedSize.width
                    + (state.expandedWidth - state.closedSize.width) * expansionProgress,
                height: state.closedSize.height + (150 - state.closedSize.height) * expansionProgress
            )
            .offset(y: state.fallbackHiddenOffset)
            .overlay(alignment: .center) {
                content
                    .frame(width: max(state.expandedWidth - 56, 100))
                    .offset(y: 12 * expansionProgress)
                    .opacity(expansionProgress)
            }
            .overlay(alignment: .bottomTrailing) {
                Text("\(state.wordsPerMinute) WPM")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
                    .opacity(expansionProgress)
            }
            .overlay(alignment: .bottomLeading) {
                if let sourceIconName = state.sourceIconName {
                    Image(systemName: sourceIconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.leading, 12)
                        .padding(.bottom, 8)
                        .opacity(expansionProgress)
                }
            }
            .animation(
                state.presentationState == .collapsing
                    ? ReaderAnimations.collapse : ReaderAnimations.expand,
                value: isExpanded
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var content: some View {
        switch state.presentationState {
        case .message(let message):
            Text(message).foregroundStyle(.white).font(.headline)
        case .expanding:
            Text(state.sourceLabel)
                .foregroundStyle(.secondary)
                .font(.caption)
        case .playing, .paused:
            if let token = state.token {
                ORPWordView(token: token)
            }
        default:
            EmptyView()
        }
    }
}

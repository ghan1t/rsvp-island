enum ReaderPresentationState: Equatable {
    case hidden
    case expanding
    case playing
    case paused
    case collapsing
    case message(String)
}

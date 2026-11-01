import SwiftUI

/// State of the article download pill on the Saved tab. The app side feeds it from the
/// article fetcher progress and decides when the pill shows.
@MainActor
public final class WMFSavedProgressViewModel: ObservableObject {

    @Published public var isVisible = false
    @Published public var fractionCompleted: Double = 0

    public init() {}
}

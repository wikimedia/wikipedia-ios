import Foundation

public final class WMFNewArticleTabViewModel {

    public let title: String
    let recentlySearchedViewModel: WMFRecentlySearchedViewModel

    public init(title: String, recentlySearchedViewModel: WMFRecentlySearchedViewModel) {
        self.title = title
        self.recentlySearchedViewModel = recentlySearchedViewModel
    }
}

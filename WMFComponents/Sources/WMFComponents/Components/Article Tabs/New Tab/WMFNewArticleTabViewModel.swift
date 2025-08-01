import Foundation

public final class WMFNewArticleTabViewModel {

    public let title: String
    public let becauseYouReadViewModel: WMFBecauseYouReadViewModel?

    public init(title: String, becauseYouReadViewModel: WMFBecauseYouReadViewModel?) {
        self.title = title
        self.becauseYouReadViewModel = becauseYouReadViewModel
    }
}

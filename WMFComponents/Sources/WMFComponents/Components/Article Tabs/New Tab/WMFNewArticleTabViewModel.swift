import Foundation

public final class WMFNewArticleTabViewModel {

    public let title: String
    public let becauseYouRedViewModel: WMFBecauseYouReadViewModel?

    public init(title: String, becauseYouRedViewModel: WMFBecauseYouReadViewModel?) {
        self.title = title
        self.becauseYouRedViewModel = becauseYouRedViewModel
    }
}

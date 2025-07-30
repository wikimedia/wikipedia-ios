import Foundation

public final class WMFNewArticleTabViewModel: ObservableObject {
    public let title: String
	public let becauseYouReadViewModel: WMFBecauseYouReadViewModel?
    public let dykViewModel: WMFNewArticleTabDidYouKnowViewModel?

    public init(title: String, becauseYouReadViewModel: WMFBecauseYouReadViewModel?, dykViewModel: WMFNewArticleTabDidYouKnowViewModel?) {
        self.title = title
        self.dykViewModel = dykViewModel
		self.becauseYouReadViewModel = becauseYouReadViewModel
    }
}

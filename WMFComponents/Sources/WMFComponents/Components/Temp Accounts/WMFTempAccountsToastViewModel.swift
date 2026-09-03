import Foundation

/// The content of the temporary account banner.
public final class WMFTempAccountsToastViewModel {
    public let didTapReadMore: () -> Void
    public let title: String
    public let readMoreButtonTitle: String

    public init(didTapReadMore: @escaping () -> Void, title: String, readMoreButtonTitle: String) {
        self.didTapReadMore = didTapReadMore
        self.title = title
        self.readMoreButtonTitle = readMoreButtonTitle
    }
}

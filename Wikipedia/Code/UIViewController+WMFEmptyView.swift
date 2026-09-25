import UIKit
import WMFComponents
import WMFNativeLocalizations

@objc enum WMFEmptyViewType: Int {
    case none
    case noFeed
    case articleDidNotLoad
    case noSearchResults
    case noSavedPages
    case noSavedPagesInReadingList
    case noInternetConnection
    case noSelectedImageToInsert
    case diffCompare
    case diffSingle
    case diffErrorCompare
    case diffErrorSingle
    case noOtherArticleLanguages
}

extension WMFEmptyViewType {

    /// The image and the text for this type. The value is nil for `.none`.
    var viewModel: WMFEmptyViewModel? {
        let content: (imageName: String?, title: String, message: String)
        switch self {
        case .none:
            return nil
        case .noFeed:
            let message = WMFLocalizedString("empty-no-feed-message", value: "You can see your recommended articles when you have internet", comment: "Body of messsage shown in place of content when no feed could be loaded. Tells users they can see the articles when the interent is restored")
            let action = WMFLocalizedString("empty-no-feed-action-message", value: "You can still read saved pages", comment: "Footer messsage shown in place of content when no feed could be loaded. Tells users they can read saved pages offline")
            content = ("no-internet", CommonStrings.noInternetConnection, "\(message)<br><br>\(action)")
        case .articleDidNotLoad:
            content = ("no-article", WMFLocalizedString("empty-no-article-message", value: "Sorry, could not load the article", comment: "Shown when an article cant be loaded in place of an article"), "")
        case .noSearchResults:
            content = (nil, WMFLocalizedString("empty-no-search-results-message", value: "No results found", comment: "Shown when there are no search results"), "")
        case .noSavedPages:
            content = ("saved-blank", CommonStrings.allArticlesEmptySavedTitle, CommonStrings.allArticlesEmptySavedSubtitle)
        case .noSavedPagesInReadingList:
            content = ("saved-blank",
                       WMFLocalizedString("empty-no-saved-pages-in-reading-list-title", value: "No pages saved to this list", comment: "Title of a blank screen shown when a user has no saved pages in a reading list"),
                       WMFLocalizedString("empty-no-saved-pages-in-reading-list-message", value: "Save pages to this list to see them appear here", comment: "Message of a blank screen shown when a user has no saved pages in a reading list"))
        case .noInternetConnection:
            content = ("no-internet-blank", CommonStrings.noInternetConnection, "")
        case .noSelectedImageToInsert:
            content = ("insert-media/blank", WMFLocalizedString("empty-insert-media-title", value: "Select a file from Wikimedia Commons", comment: "Text for placeholder label visible when no file was selected or uploaded"), "")
        case .diffCompare:
            content = ("empty-diff", WMFLocalizedString("empty-diff-compare-title", value: "No differences between revisions", comment: "Text for placeholder label visible when diff comparison between revisions is empty."), "")
        case .diffSingle:
            content = ("empty-single-diff", WMFLocalizedString("empty-diff-single-title", value: "No viewable changes made", comment: "Text for placeholder label visible when diff returned for single revision is empty."), "")
        case .diffErrorCompare:
            content = ("error-diff", CommonStrings.diffErrorTitle, "")
        case .diffErrorSingle:
            content = ("error-single-diff", CommonStrings.diffErrorTitle, "")
        case .noOtherArticleLanguages:
            content = ("no-other-article-languages",
                       WMFLocalizedString("empty-no-other-article-languages-title", value: "No other languages available", comment: "Title text shown in place of languages list when when no alternative article languages exist."),
                       WMFLocalizedString("empty-no-other-article-languages-message", value: "This article has not yet been written in any other languages", comment: "Message text shown in place of languages list when when no alternative article languages exist."))
        }

        let localizedStrings = WMFEmptyViewModel.LocalizedStrings(title: content.title, subtitle: content.message, titleFilter: nil, buttonTitle: nil, attributedFilterString: nil)
        let image = content.imageName.flatMap { UIImage(named: $0) }
        return WMFEmptyViewModel(localizedStrings: localizedStrings, image: image, imageColor: nil, numberOfFilters: nil)
    }

    /// A new empty view for this type. The value is nil for `.none`.
    func makeView() -> WMFEmptyHostingView? {
        guard let viewModel else {
            return nil
        }
        return WMFEmptyHostingView(viewModel: viewModel)
    }
}

extension UIViewController {

    /// The empty view that is a subview of `view`, if there is one.
    @objc var wmf_emptyView: UIView? {
        return viewIfLoaded?.subviews.first { $0 is WMFEmptyHostingView }
    }

    /// Replaces the current empty view with a new empty view of the given type.
    @objc(wmf_showEmptyViewOfType:frame:)
    func wmf_showEmptyView(of type: WMFEmptyViewType, frame: CGRect) {
        wmf_hideEmptyView()

        guard let emptyView = type.makeView() else {
            return
        }

        (view as? UIScrollView)?.isScrollEnabled = false
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        emptyView.frame = frame
        view.addSubview(emptyView)
    }

    @objc func wmf_hideEmptyView() {
        (viewIfLoaded as? UIScrollView)?.isScrollEnabled = true
        wmf_emptyView?.removeFromSuperview()
    }

    @objc func wmf_isShowingEmptyView() -> Bool {
        return wmf_emptyView != nil
    }

    @objc func wmf_setEmptyViewFrame(_ frame: CGRect) {
        wmf_emptyView?.frame = frame
    }
}

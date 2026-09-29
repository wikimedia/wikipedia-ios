import WMFComponents
import WMFNativeLocalizations

extension ArticleViewController {

    /// Highlights the passages of the semantic search result, once, after the final setup of the
    /// page. The scroll to the section runs on its own; the highlight does not wait for it.
    func highlightSemanticSearchPassages() {
        let passages = semanticSearchPassages
        guard !passages.isEmpty else { return }

        semanticSearchPassages = []
        let anchor = articleURL.fragment?.removingPercentEncoding
        messagingController.highlightPassages(passages, anchor: anchor) { highlightedCount in
            guard highlightedCount == 0 else { return }

            WMFToastManager.sharedInstance.showToast(Self.passageNotFoundMessage, sticky: false, dismissPreviousToasts: true)
        }
    }

    private static let passageNotFoundMessage = WMFLocalizedString("semantic-search-passage-not-found", value: "This passage is no longer in the article", comment: "Message shown after opening an article from a passage found by the search, when the passage is not in the article anymore.")
}

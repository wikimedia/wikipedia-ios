import WMFComponents
import WMFNativeLocalizations

extension ArticleViewController {

    /// Where the article scrolls to, once the web view is in sync with the page.
    struct SemanticSearchScroll {
        let anchor: String
        let centered: Bool
    }

    /// Highlights the passages of the semantic search result, once, after the final setup of the
    /// page, and opens the article centered on the first passage. When no passage is found, the
    /// article opens at the section instead.
    func highlightSemanticSearchPassages() {
        let passages = semanticSearchPassages
        guard !passages.isEmpty else { return }

        semanticSearchPassages = []
        let sectionAnchor = articleURL.fragment?.removingPercentEncoding
        messagingController.highlightPassages(passages, anchor: sectionAnchor) { [weak self] highlightIDs in
            guard let self else { return }

            let target: SemanticSearchScroll
            if let firstHighlightID = highlightIDs.first {
                target = SemanticSearchScroll(anchor: firstHighlightID, centered: true)
            } else {
                WMFToastManager.sharedInstance.showToast(Self.passageNotFoundMessage, sticky: false, dismissPreviousToasts: true)
                guard let sectionAnchor else { return }
                target = SemanticSearchScroll(anchor: sectionAnchor, centered: false)
            }

            // The sections of the page show up after the final setup. Until then the page has the
            // height of the lead only, and the target has no position yet.
            messagingController.sectionsAreShown { [weak self] in
                guard let self else { return }
                pendingSemanticSearchScroll = target
                scrollToSemanticSearchTargetIfReady()
            }
        }
    }

    /// The web view reports the height of the page some time after the page changes it. The scroll
    /// runs once the two heights are the same, so that the target is at its position in the web
    /// view, as in find in page. `debouncedContentSizeDidChange` calls this again while the web view
    /// catches up.
    func scrollToSemanticSearchTargetIfReady() {
        guard pendingSemanticSearchScroll != nil else { return }

        messagingController.pageHeight { [weak self] pageHeight in
            guard let self,
                  let target = pendingSemanticSearchScroll,
                  abs(webView.scrollView.contentSize.height - pageHeight) < 1 else {
                return
            }

            pendingSemanticSearchScroll = nil
            scroll(to: target.anchor, centered: target.centered, animated: false) { [weak self] _ in
                self?.setWebViewHidden(false, animated: true)
            }
        }
    }

    private static let passageNotFoundMessage = WMFLocalizedString("semantic-search-passage-not-found", value: "This passage is no longer in the article", comment: "Message shown after opening an article from a passage found by the search, when the passage is not in the article anymore.")
}

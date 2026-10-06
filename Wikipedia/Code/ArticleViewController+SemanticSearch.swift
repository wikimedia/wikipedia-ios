import WMFComponents
import WMFNativeLocalizations

extension ArticleViewController {

    /// Where the article scrolls to, once the web view is in sync with the page.
    struct SemanticSearchScroll {
        enum Target {
            /// The id of an element, e.g. the section heading.
            case anchor(String)
            /// A vertical position in the content of the web view's scroll view.
            case offset(CGFloat)
        }
        let target: Target
        let centered: Bool
    }

    /// Highlights a passage of the semantic search result, once, after the final setup of the page,
    /// and opens the article centered on it. When no passage is found, the article opens at the
    /// section instead.
    func highlightSemanticSearchPassages() {
        let passages = semanticSearchPassages
        guard !passages.isEmpty else { return }

        semanticSearchPassages = []
        let sectionAnchor = articleURL.fragment?.removingPercentEncoding

        // The sections of the page show up after the final setup. Until then the page has the
        // height of the lead only, and the passage has no position yet.
        messagingController.sectionsAreShown { [weak self] in
            guard let self else { return }

            messagingController.highlightPassage(passages, anchor: sectionAnchor) { [weak self] result in
                guard let self else { return }

                let target: SemanticSearchScroll
                switch result {
                case .highlighted(let rect):
                    target = SemanticSearchScroll(target: .offset(rect.midY + webView.scrollView.contentOffset.y), centered: true)
                case .notFound:
                    WMFToastManager.sharedInstance.showToast(Self.passageNotFoundMessage, sticky: false, dismissPreviousToasts: true)
                    fallthrough
                case .unavailable:
                    guard let sectionAnchor else { return }
                    target = SemanticSearchScroll(target: .anchor(sectionAnchor), centered: false)
                }

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
            let completion: (Bool) -> Void = { [weak self] _ in
                self?.setWebViewHidden(false, animated: true)
            }
            switch target.target {
            case .anchor(let anchor):
                scroll(to: anchor, centered: target.centered, animated: false, completion: completion)
            case .offset(let y):
                scroll(to: CGPoint(x: webView.scrollView.contentOffset.x, y: y), centered: target.centered, animated: false, completion: completion)
            }
        }
    }

    private static let passageNotFoundMessage = WMFLocalizedString("semantic-search-passage-not-found", value: "This passage is no longer in the article", comment: "Message shown after opening an article from a passage found by the search, when the passage is not in the article anymore.")
}

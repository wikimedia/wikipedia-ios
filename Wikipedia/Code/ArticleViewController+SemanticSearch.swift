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

    // MARK: - Feedback

    private static let semanticSearchFeedbackDelay: Duration = .seconds(5)

    /// Asks for feedback on the search a moment after the reader lands on the article, if they
    /// opened it from a passage and ignored the prompt in the sheet of passages.
    func scheduleSemanticSearchFeedbackIfNeeded() {
        guard needsSemanticSearchFeedback, semanticSearchFeedbackTask == nil else { return }

        semanticSearchFeedbackTask = Task { [weak self] in
            try? await Task.sleep(for: Self.semanticSearchFeedbackDelay)
            guard !Task.isCancelled, let self else { return }

            self.semanticSearchFeedbackTask = nil
            self.presentSemanticSearchFeedback()
        }
    }

    /// The reader moved on, or started doing something else in the article. The prompt doesn't
    /// come back for this article.
    func skipSemanticSearchFeedback() {
        needsSemanticSearchFeedback = false
        semanticSearchFeedbackTask?.cancel()
        semanticSearchFeedbackTask = nil
    }

    /// Nothing else has the reader's attention: no other screen on top (a modal, popover, share
    /// sheet, the table of contents in compact widths, or another pushed screen) and no find in page.
    private var canPresentSemanticSearchFeedback: Bool {
        view.window != nil
            && presentedViewController == nil
            && navigationController?.topViewController === self
            && findInPage.view == nil
    }

    private func presentSemanticSearchFeedback() {
        guard canPresentSemanticSearchFeedback else {
            skipSemanticSearchFeedback()
            return
        }

        needsSemanticSearchFeedback = false

        let viewModel = WMFSemanticSearchFeedbackViewModel(
            style: .card,
            submitAction: { [weak self] _, _ in
                // TODO: Send the rating and optional text the reader submits.
                self?.dismissSemanticSearchFeedback(showingThanks: true)
            },
            closeAction: { [weak self] in
                self?.dismissSemanticSearchFeedback(showingThanks: false)
            }
        )

        present(WMFSemanticSearchFeedbackHostingController(viewModel: viewModel), animated: true)
    }

    private func dismissSemanticSearchFeedback(showingThanks: Bool) {
        guard presentedViewController is WMFSemanticSearchFeedbackHostingController else { return }

        dismiss(animated: true) {
            guard showingThanks else { return }
            WMFToastManager.sharedInstance.showToast(WMFSemanticSearchFeedbackViewModel.thanksToastTitle(), sticky: false, dismissPreviousToasts: true)
        }
    }

    private static let passageNotFoundMessage = WMFLocalizedString("semantic-search-passage-not-found", value: "This passage is no longer in the article", comment: "Message shown after opening an article from a passage found by the search, when the passage is not in the article anymore.")
}

import Foundation

protocol ReferenceShowing: ArticleScrolling {
    var webView: WKWebView { get }
    var articleURL: URL { get }
//    var articleURL: URL? { get }
}

extension ReferenceShowing where Self: ViewController & WMFReferencePageViewAppearanceDelegate & UIPageViewControllerDelegate & ReferenceViewControllerDelegate {
    // MARK: - Actions

    /// Show references that were tapped in the article
    /// For now, we're keeping WMFReference to bridge with Objective-C but it should be merged with Reference in the future
    func showReferences(_ scriptMessageReferences: [WMFLegacyReference], selectedIndex: Int, animated: Bool) {
        guard selectedIndex < scriptMessageReferences.count else {
            showGenericError()
            return
        }

        let referencesBoundingClientRect = getBoundingClientRect(for: scriptMessageReferences)
        let referenceRectInScrollCoordinates = webView.scrollView.convert(referencesBoundingClientRect, from: webView)
        if traitCollection.verticalSizeClass == .compact || self.traitCollection.horizontalSizeClass == .compact {
            showReferencesPanel(with: scriptMessageReferences, referencesBoundingClientRect: referencesBoundingClientRect, referenceRectInScrollCoordinates: referenceRectInScrollCoordinates, selectedIndex: selectedIndex, animated: animated)
        } else {
            if !isBoundingClientRectVisible(referencesBoundingClientRect) {
                let center = referenceRectInScrollCoordinates.center
                scroll(to: center, centered: true, animated: true) { [weak self] (_) in
                    self?.showReferencesPopover(with: scriptMessageReferences[selectedIndex], referenceRectInScrollCoordinates: referenceRectInScrollCoordinates, animated: animated)
                }
            } else {
                showReferencesPopover(with: scriptMessageReferences[selectedIndex], referenceRectInScrollCoordinates: referenceRectInScrollCoordinates, animated: animated)
            }
        }
    }

    /// Show references that were tapped in the article as a panel
    func showReferencesPanel(with references: [WMFLegacyReference], referencesBoundingClientRect: CGRect, referenceRectInScrollCoordinates: CGRect, selectedIndex: Int, animated: Bool) {
        let vc = WMFReferencePageViewController.wmf_viewControllerFromReferencePanelsStoryboard()
        vc.delegate = self
        vc.pageViewController.delegate = self
        vc.appearanceDelegate = self
        vc.apply(theme: theme)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.lastClickedReferencesIndex = selectedIndex
        vc.lastClickedReferencesGroup = references
        vc.articleURL = articleURL
        present(vc, animated: false) { // should be false even if animated is true
            self.adjustScrollForReferencePageViewController(referencesBoundingClientRect, referenceRectInScrollCoordinates: referenceRectInScrollCoordinates, viewController: vc, animated: animated)
        }
    }

    /// Show references that were tapped in the article as a popover
    func showReferencesPopover(with reference: WMFLegacyReference, referenceRectInScrollCoordinates: CGRect, animated: Bool) {
        let width = min(min(view.frame.size.width, view.frame.size.height) - 20, 355);
        guard let popoverVC = WMFReferencePopoverMessageViewController.wmf_initialViewControllerFromClassStoryboard() else {
            showGenericError()
            return
        }
        popoverVC.articleURL = articleURL
        (popoverVC as Themeable).apply(theme: theme)
        popoverVC.modalPresentationStyle = .popover
        popoverVC.reference = reference
        popoverVC.width = width
        popoverVC.view.backgroundColor = theme.colors.paperBackground

        let presenter = popoverVC.popoverPresentationController
        presenter?.passthroughViews = [webView]
        presenter?.delegate = popoverVC
        presenter?.permittedArrowDirections = [.up, .down]
        presenter?.backgroundColor = theme.colors.paperBackground;
        presenter?.sourceView = view
        presenter?.sourceRect = view.convert(referenceRectInScrollCoordinates, from: webView.scrollView)

        present(popoverVC, animated: animated) {
            // Reminder: The textView's scrollEnabled needs to remain "NO" until after the popover is
            // presented. (When scrollEnabled is NO the popover can better determine the textView's
            // full content height.) See the third reference "[3]" on "enwiki > Pythagoras".
            popoverVC.scrollEnabled = true
        }
    }
}

private extension ReferenceShowing where Self: ViewController  {
    // MARK: - Utilities
    func getBoundingClientRect(for references: [WMFLegacyReference]) -> CGRect {
        guard var rect = references.first?.rect else {
            return .zero
        }
        for reference in references {
            rect = rect.union(reference.rect)
        }
        rect = rect.offsetBy(dx: 0, dy: 1)
        rect = rect.insetBy(dx: -1, dy: -3)
        return rect
    }

    func adjustScrollForReferencePageViewController(_ referencesBoundingClientRect: CGRect, referenceRectInScrollCoordinates: CGRect, viewController: WMFReferencePageViewController, animated: Bool) {
        let deltaY = webView.scrollView.contentOffset.y < 0 ? 0 - webView.scrollView.contentOffset.y : 0
        let referenceRectInWindowCoordinates = webView.scrollView.convert(referenceRectInScrollCoordinates, to: nil).offsetBy(dx: 0, dy: deltaY)
        guard
            !referenceRectInWindowCoordinates.isEmpty,
            let firstPanel = viewController.firstPanelView()
        else {
                return
        }
        let panelRectInWindowCoordinates = firstPanel.convert(firstPanel.bounds, to: nil)
        guard !isBoundingClientRectVisible(referencesBoundingClientRect) || referenceRectInWindowCoordinates.intersects(panelRectInWindowCoordinates) else {
            viewController.backgroundView.clearRect = referenceRectInWindowCoordinates
            return
        }

        let oldY = webView.scrollView.contentOffset.y
        let scrollPoint = referenceRectInScrollCoordinates.offsetBy(dx: 0, dy: 0.5 * panelRectInWindowCoordinates.height).center
        scroll(to: scrollPoint, centered: true, animated: animated) { [weak self] (_) in
            guard let newY = self?.webView.scrollView.contentOffset.y else {
                return
            }
            let delta = newY - oldY
            viewController.backgroundView.clearRect = referenceRectInWindowCoordinates.offsetBy(dx: 0, dy: 0 - delta)
        }
    }
}

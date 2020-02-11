import Foundation

extension ArticleViewController {
    // MARK: - Actions
    
    /// Show references that were tapped in the article
    /// For now, we're keeping WMFReference to bridge with Objective-C but it should be merged with Reference in the future
    func showReferences(_ scriptMessageReferences: [WMFLegacyReference], selectedIndex: Int, animated: Bool) {
        guard selectedIndex < scriptMessageReferences.count else {
            showGenericError()
            return
        }
        
        let referenceRectInWindowCoordinates = getBoundingClientRect(for: scriptMessageReferences)
        if traitCollection.verticalSizeClass == .compact || self.traitCollection.horizontalSizeClass == .compact {
            showReferencesPanel(with: scriptMessageReferences, referenceRectInWindowCoordinates: referenceRectInWindowCoordinates, selectedIndex: selectedIndex, animated: animated)
        } else {
            if !isWindowCoordinatesRectVisible(referenceRectInWindowCoordinates) {
                let referenceRectInScrollCoordinates = webView.scrollView.convert(referenceRectInWindowCoordinates, from: nil)
                let center = referenceRectInScrollCoordinates.center
                scroll(to: center, centered: true, animated: true) {
                    self.showReferencesPopover(with: scriptMessageReferences[selectedIndex], animated: animated)
                }
            } else {
                showReferencesPopover(with: scriptMessageReferences[selectedIndex], animated: animated)
            }
        }
    }
    
    /// Show references that were tapped in the article as a panel
    func showReferencesPanel(with references: [WMFLegacyReference], referenceRectInWindowCoordinates: CGRect, selectedIndex: Int, animated: Bool) {
        let vc = WMFReferencePageViewController.wmf_viewControllerFromReferencePanelsStoryboard()
        vc.pageViewController.delegate = self
        vc.appearanceDelegate = self
        vc.apply(theme: theme)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.lastClickedReferencesIndex = selectedIndex
        vc.lastClickedReferencesGroup = references
        present(vc, animated: false) { // should be false even if animated is true
            self.adjustScrollForReferencePageViewController(referenceRectInWindowCoordinates, viewController: vc, animated: animated)
        }
    }
    
    /// Show references that were tapped in the article as a popover
    func showReferencesPopover(with reference: WMFLegacyReference, animated: Bool) {
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
        presenter?.sourceView = webView
        presenter?.sourceRect = reference.rect
        
        present(popoverVC, animated: animated) {
            // Reminder: The textView's scrollEnabled needs to remain "NO" until after the popover is
            // presented. (When scrollEnabled is NO the popover can better determine the textView's
            // full content height.) See the third reference "[3]" on "enwiki > Pythagoras".
            popoverVC.scrollEnabled = true
        }
    }
    
    func dismissReferencesPopover() {
        guard presentedViewController is WMFReferencePopoverMessageViewController || presentedViewController is WMFReferencePageViewController else {
            return
        }
        dismiss(animated: true)
    }
}

private extension ArticleViewController {
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

    func adjustScrollForReferencePageViewController(_ referenceRectInWindowCoordinates: CGRect, viewController: WMFReferencePageViewController, animated: Bool) {
        let referenceRectInScrollCoordinates = webView.scrollView.convert(referenceRectInWindowCoordinates, from: nil)
        guard
            !referenceRectInWindowCoordinates.isEmpty,
            let firstPanel = viewController.firstPanelView()
        else {
                return
        }
        let panelRectInWindowCoordinates = firstPanel.convert(firstPanel.bounds, to: nil)
        guard !isWindowCoordinatesRectVisible(referenceRectInWindowCoordinates) || referenceRectInWindowCoordinates.intersects(panelRectInWindowCoordinates) else {
            viewController.backgroundView.clearRect = referenceRectInWindowCoordinates
            return
        }
        
        let oldY = webView.scrollView.contentOffset.y
        let scrollPoint = referenceRectInScrollCoordinates.offsetBy(dx: 0, dy: 0.5 * panelRectInWindowCoordinates.height).center
        scroll(to: scrollPoint, centered: true, animated: animated) {
            let newY = self.webView.scrollView.contentOffset.y
            let delta = newY - oldY
            viewController.backgroundView.clearRect = referenceRectInWindowCoordinates.offsetBy(dx: 0, dy: 0 - delta)
        }
    }
}

extension ArticleViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            let firstRefVC = pageViewController.viewControllers?.first as? WMFReferencePanelViewController,
            let refId = firstRefVC.reference?.refId
            else {
                return
        }
        webView.wmf_highlightLinkID(refId)
    }
}

extension ArticleViewController: WMFReferencePageViewAppearanceDelegate {
    func referencePageViewControllerWillAppear(_ referencePageViewController: WMFReferencePageViewController) {
        guard
            let firstRefVC = referencePageViewController.pageViewController.viewControllers?.first as? WMFReferencePanelViewController,
            let refId = firstRefVC.reference?.refId
            else {
                return
        }
        webView.wmf_highlightLinkID(refId)
    }
    
    func referencePageViewControllerWillDisappear(_ referencePageViewController: WMFReferencePageViewController) {
        for vc in referencePageViewController.pageViewController.viewControllers ?? [] {
            guard
                let panel = vc as? WMFReferencePanelViewController,
                let refId = panel.reference?.refId
                else {
                    continue
            }
            webView.wmf_unHighlightLinkID(refId)
        }
    }
}

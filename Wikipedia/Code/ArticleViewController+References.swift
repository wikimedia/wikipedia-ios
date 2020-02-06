import Foundation

extension ArticleViewController {
    // MARK: - Actions
    /// Show the entire references list modally
    func showReferencesList() {
        guard let references = references else {
            showGenericError()
            return
        }
        let referencesVC = ReferencesViewController(articleURL: articleURL, references: references, theme: theme, delegate: self)
        presentEmbedded(referencesVC, style: .sheet)
    }
    
    /// Show references that were tapped in the article
    /// For now, we're keeping WMFReference to bridge with Objective-C but it should be merged with Reference in the future
    func showReferences(_ scriptMessageReferences: [WMFLegacyReference], remoteReferences maybeRemoteReferences: [Reference]? = nil, selectedIndex: Int, animated: Bool) {
        guard selectedIndex < scriptMessageReferences.count else {
            showGenericError()
            return
        }
        
        let remoteReferences: [Reference]
        if let refs = maybeRemoteReferences {
            remoteReferences = refs
        } else {
            remoteReferences = scriptMessageReferences.compactMap { getRemoteReferenceAndID(with: $0.refId)?.reference }
        }
        
        guard remoteReferences.count == scriptMessageReferences.count else {
            return
        }
        // Read the reference HTML from the full references fetched from the server
        for (i, reference) in scriptMessageReferences.enumerated() {
            reference.html = remoteReferences[i].content.html
        }
        
        if traitCollection.verticalSizeClass == .compact || traitCollection.horizontalSizeClass == .compact {
            showReferencesPanel(with: scriptMessageReferences, selectedIndex: selectedIndex, animated: animated)
        } else {
            showReferencesPopover(with: scriptMessageReferences[selectedIndex], animated: animated)
        }
    }
    
    /// Show references that were tapped in the article as a panel
    func showReferencesPanel(with references: [WMFLegacyReference], selectedIndex: Int, animated: Bool) {
        let vc = WMFReferencePageViewController.wmf_viewControllerFromReferencePanelsStoryboard()
        vc.pageViewController.delegate = self
        vc.appearanceDelegate = self
        vc.apply(theme: theme)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.lastClickedReferencesIndex = selectedIndex
        vc.lastClickedReferencesGroup = references
        present(vc, animated: false) { // should be false even if animated is true
            self.scrollReferencesToVisible(references, viewController: vc, animated: animated)
        }
    }
    
    /// Show references that were tapped in the article as a popover
    func showReferencesPopover(with reference: WMFLegacyReference, animated: Bool) {
        let width = min(min(view.frame.size.width, view.frame.size.height) - 20, 355);
        guard let popoverVC = WMFReferencePopoverMessageViewController.wmf_initialViewControllerFromClassStoryboard() else {
            showGenericError()
            return
        }
        
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
    func windowCoordinatesRect(for references: [WMFLegacyReference]) -> CGRect {
        guard var rect = references.first?.rect else {
            return .zero
        }
        for reference in references {
            rect = rect.union(reference.rect)
        }
        rect = webView.convert(rect, to: nil)
        rect = rect.offsetBy(dx: 0, dy: 1)
        rect = rect.insetBy(dx: -1, dy: -3)
        return rect
    }

    func scrollReferencesToVisible(_ references: [WMFLegacyReference], viewController: WMFReferencePageViewController, animated: Bool) {
        let windowCoordsRefGroupRect = windowCoordinatesRect(for: references)
        guard
            !windowCoordsRefGroupRect.isEmpty,
            let firstPanel = viewController.firstPanelView()
            else {
                return
        }
        let panelRectInWindowCoords = firstPanel.convert(firstPanel.bounds, to: nil)
        let refGroupRectInWindowCoords = viewController.backgroundView.convert(windowCoordsRefGroupRect, to: nil)
        
        guard !windowCoordsRefGroupRect.intersects(view.bounds) || windowCoordsRefGroupRect.intersects(panelRectInWindowCoords) else {
            viewController.backgroundView.clearRect = windowCoordsRefGroupRect
            return
        }
        
        let refGroupScrollOffsetY = webView.scrollView.contentOffset.y + refGroupRectInWindowCoords.minY
        var newOffsetY: CGFloat = refGroupScrollOffsetY - 0.5 * panelRectInWindowCoords.minY + 0.5 * refGroupRectInWindowCoords.height - 0.5 * navigationBar.visibleHeight
        let contentInsetTop = webView.scrollView.contentInset.top
        if newOffsetY <= 0 - contentInsetTop {
            newOffsetY = 0 - contentInsetTop
            navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 0, shadowAlpha: 1, animated: animated, additionalAnimations: nil)
        }
        let delta = webView.scrollView.contentOffset.y - newOffsetY
        let centeredOffset = CGPoint(x: webView.scrollView.contentOffset.x, y: newOffsetY)
        scroll(to: centeredOffset, animated: animated) {
            viewController.backgroundView.clearRect = windowCoordsRefGroupRect.offsetBy(dx: 0, dy: delta)
        }
    }


    func getRemoteReferenceAndID(with anchor: String) -> (id: String, reference: Reference)? {
        guard let referencesByID = references?.referencesByID  else {
            return nil
        }
        // There should be a better way to do this...
        for (id, reference) in referencesByID {
            for backLink in reference.backLinks {
                guard backLink.href.contains("#" + anchor) else {
                    continue
                }
                return (id, reference)
            }
        }
        return nil
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

extension ArticleViewController: ReferencesViewControllerDelegate {
    func referencesViewController(_ referencesViewController: ReferencesViewController, userDidTapAnchor anchor: String) {
        guard let remoteReferenceAndID = getRemoteReferenceAndID(with: anchor) else {
            dismiss(animated: true)
            showGenericError()
            return
        }
        let remoteReference = remoteReferenceAndID.reference
        let remoteReferenceID = remoteReferenceAndID.id
        
        webView.getScrollRectForHtmlElement(withId: anchor) { (rect) in
            guard !rect.isNull else {
                self.dismiss(animated: true)
                self.showGenericError()
                return
            }
            let offset = self.webView.scrollView.contentOffset
            let convertedOrigin = CGPoint(x: rect.origin.x - offset.x, y: rect.origin.y - offset.y)
            let convertedRect = CGRect(origin: convertedOrigin, size: rect.size)
            let scriptMessageReference = WMFLegacyReference(html: remoteReference.content.html, refId: remoteReferenceID, anchor: anchor, rect: convertedRect, text: "")
            self.dismiss(animated: true)
            self.showReferences([scriptMessageReference], remoteReferences: [remoteReference], selectedIndex: 0, animated: false)
        }

    }
    
    func referencesViewControllerUserDidTapClose(_ referencesViewController: ReferencesViewController) {
        dismiss(animated: true)
    }
}

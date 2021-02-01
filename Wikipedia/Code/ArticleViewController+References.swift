import Foundation

extension ArticleViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        didFinishAnimating(pageViewController)
    }
}


extension ArticleViewController: ReferenceBackLinksViewControllerDelegate, WMFReferencePageViewAppearanceDelegate, ReferenceShowing {
    func referenceViewControllerUserDidTapClose(_ vc: ReferenceViewController) {
        if vc is ReferenceBackLinksViewController {
            dismissReferenceBackLinksViewController()
        } else {
            dismissReferencesPopover()
        }
    }

    func referenceBackLinksViewControllerUserDidNavigateTo(referenceBackLink: ReferenceBackLink, referenceBackLinksViewController: ReferenceBackLinksViewController) {
        scroll(to: referenceBackLink.id, centered: true, highlighted: true, animated: true) { [weak self] (_) in
            self?.webView.wmf_accessibilityCursor(toFragment: referenceBackLink.id)
            self?.updateTableOfContentsHighlight()
        }
    }
    
    func referenceViewControllerUserDidNavigateBackToReference(_ vc: ReferenceViewController) {
        referenceViewControllerUserDidTapClose(vc)
        guard let referenceId = vc.referenceId else {
            showGenericError()
            return
        }
        let backLink = "back_link_\(referenceId)"
        scroll(to: backLink, highlighted: true, animated: true) { [weak self] (_) in
            self?.webView.wmf_accessibilityCursor(toFragment: backLink)
            self?.updateTableOfContentsHighlight()
            dispatchOnMainQueueAfterDelayInSeconds(1.0) { [weak self] in
                self?.messagingController.removeElementHighlights()
            }
        }
    }
    
    @objc func tappedWebViewBackground() {
        dismissReferenceBackLinksViewController()
    }
}

extension ArticleViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldRecognizeSimultaneousGesture(recognizer: gestureRecognizer)
    }
}

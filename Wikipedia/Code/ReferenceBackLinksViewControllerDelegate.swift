protocol ReferenceBackLinksViewControllerDelegate: ArticleScrolling, ReferenceViewControllerDelegate, UIGestureRecognizerDelegate {
    func referenceBackLinksViewControllerUserDidNavigateTo(referenceBackLink: ReferenceBackLink, referenceBackLinksViewController: ReferenceBackLinksViewController)
}

extension ReferenceBackLinksViewControllerDelegate where Self: ViewController {
    func referenceBackLinksViewControllerUserDidNavigateTo(referenceBackLink: ReferenceBackLink, referenceBackLinksViewController: ReferenceBackLinksViewController) {
        scroll(to: referenceBackLink.id, centered: true, highlighted: true, animated: true)
    }

    func showReferenceBackLinks(_ backLinks: [ReferenceBackLink], referenceId: String, referenceText: String) {
        guard let vc = ReferenceBackLinksViewController(referenceId: referenceId, referenceText: referenceText, backLinks: backLinks, delegate: self, theme: theme) else {
            showGenericError()
            return
        }
        addChild(vc)
        view.wmf_addSubviewWithConstraintsToEdges(vc.view)
        vc.didMove(toParent: self)
        referenceWebViewBackgroundTapGestureRecognizer.isEnabled = true
    }

    func referenceViewControllerUserDidTapClose(_ vc: ReferenceViewController) {
        if vc is ReferenceBackLinksViewController {
            dismissReferenceBackLinksViewController()
        } else {
            dismissReferencesPopover()
        }
    }

    func dismissReferencesPopover() {
        guard presentedViewController is WMFReferencePopoverMessageViewController || presentedViewController is WMFReferencePageViewController else {
            return
        }
        dismiss(animated: true)
    }

    func dismissReferenceBackLinksViewController() {
        let vc = children.first { $0 is ReferenceBackLinksViewController }
        vc?.willMove(toParent: nil)
        vc?.view.removeFromSuperview()
        vc?.removeFromParent()
        messagingController.removeElementHighlights()
        referenceWebViewBackgroundTapGestureRecognizer.isEnabled = false
    }

    func referenceViewControllerUserDidNavigateBackToReference(_ vc: ReferenceViewController) {
        referenceViewControllerUserDidTapClose(vc)
        guard let referenceId = vc.referenceId else {
            showGenericError()
            return
        }
        scroll(to: "back_link_\(referenceId)", highlighted: true, animated: true) { [weak self] (_) in
            dispatchOnMainQueueAfterDelayInSeconds(1.0) { [weak self] in
                self?.messagingController.removeElementHighlights()
            }
        }
    }

    func shouldRecognizeSimultaneousGesture(recognizer gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === referenceWebViewBackgroundTapGestureRecognizer {
            return true
        }

        return false //default
    }
}

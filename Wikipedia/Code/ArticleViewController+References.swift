import Foundation

extension ArticleViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        didFinishAnimating(pageViewController)
    }
}

extension ArticleViewController: WMFReferencePageViewAppearanceDelegate, ReferenceBackLinksViewControllerDelegate, ReferenceShowing {
    @objc func tappedWebViewBackground() {
        dismissReferenceBackLinksViewController()
    }
}

extension ArticleViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldRecognizeSimultaneousGesture(recognizer: gestureRecognizer)
    }
}

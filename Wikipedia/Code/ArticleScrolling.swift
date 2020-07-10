import Foundation

protocol ArticleScrolling: class {
    /// Used to wait for the callback that the anchor is ready for scrollin'
    typealias ScrollToAnchorCompletion = (_ anchor: String, _ rect: CGRect) -> Void

    var webView: WKWebView { get }
    var messagingController: ArticleWebMessagingController { get }
    var scrollToAnchorCompletions: [ScrollToAnchorCompletion] { get set }
    var scrollViewAnimationCompletions: [() -> Void] { get set }
}

extension ArticleScrolling where Self: ViewController {
    /// Must set `webView.scrollView.delegate = self` in `viewDidLoad`, as it is not permitted to override functions in extensions.

    // There is also some related code in ViewController.scrollViewDidEndScrollingAnimation
    // It's a tad hacky, but we need to call something on it and the function can't be overridden here.

    func scroll(to anchor: String, centered: Bool = false, highlighted: Bool = false, animated: Bool, completion: (() -> Void)? = nil) {
        guard !anchor.isEmpty else {
            webView.scrollView.scrollRectToVisible(CGRect(x: 0, y: 1, width: 1, height: 1), animated: animated)
            completion?()
            return
        }

        messagingController.prepareForScroll(to: anchor, highlight: highlighted) { (result) in
            assert(Thread.isMainThread)
            switch result {
            case .failure(let error):
                self.showError(error)
                completion?()
            case .success:
                let scrollCompletion: ScrollToAnchorCompletion = { (anchor, rect) in
                    let point = CGPoint(x: self.webView.scrollView.contentOffset.x, y: rect.origin.y + self.webView.scrollView.contentOffset.y)
                    self.scroll(to: point, centered: centered, animated: animated, completion: completion)
                }
                self.scrollToAnchorCompletions.insert(scrollCompletion, at: 0)
            }
        }
    }

    func scroll(to offset: CGPoint, centered: Bool = false, animated: Bool, completion: (() -> Void)? = nil) {
        assert(Thread.isMainThread)
        let scrollView = webView.scrollView
        guard !offset.x.isNaN && !offset.x.isInfinite && !offset.y.isNaN && !offset.y.isInfinite else {
            completion?()
            return
        }
        let overlayTop = self.webView.iOS12yOffsetHack + self.navigationBar.hiddenHeight
        let adjustmentY: CGFloat
        if centered {
            let overlayBottom = self.webView.scrollView.contentInset.bottom
            let height = self.webView.scrollView.bounds.height
            adjustmentY = -0.5 * (height - overlayTop - overlayBottom)
        } else {
            adjustmentY = overlayTop
        }
        let minY = 0 - scrollView.contentInset.top
        let maxY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom
        let boundedY = min(maxY,  max(minY, offset.y + adjustmentY))
        let boundedOffset = CGPoint(x: scrollView.contentOffset.x, y: boundedY)
        guard WMFDistanceBetweenPoints(boundedOffset, scrollView.contentOffset) >= 2 else {
            scrollView.flashScrollIndicators()
            completion?()
            return
        }
        guard animated else {
            scrollView.setContentOffset(boundedOffset, animated: false)
            completion?()
            return
        }
        /*
         Setting scrollView.contentOffset inside of an animation block
         results in a broken animation https://phabricator.wikimedia.org/T232689
         Calling [scrollView setContentOffset:offset animated:YES] inside
         of an animation block fixes the animation but doesn't guarantee
         the content offset will be updated when the animation's completion
         block is called.
         It appears the only reliable way to get a callback after the default
         animation is to use scrollViewDidEndScrollingAnimation
         */
        if let completion = completion {
            scrollViewAnimationCompletions.insert(completion, at: 0)
        }
        scrollView.setContentOffset(boundedOffset, animated: true)
    }

    func isBoundingClientRectVisible(_ rect: CGRect) -> Bool {
        let scrollView = webView.scrollView
        return rect.minY > scrollView.contentInset.top && rect.maxY < scrollView.bounds.size.height - scrollView.contentInset.bottom
    }
}

import Foundation

protocol ArticleScrolling: AnyObject {
    /// Used to wait for the callback that the anchor is ready for scrollin'
    typealias ScrollToAnchorCompletion = (_ anchor: String, _ rect: CGRect) -> Void

    var webView: WKWebView { get }
    var messagingController: ArticleWebMessagingController { get }
    var scrollToAnchorCompletions: [ScrollToAnchorCompletion] { get set }
    var scrollViewAnimationCompletions: [() -> Void] { get set }
}

// Must set `webView.scrollView.delegate = self` in `viewDidLoad`, as it is not permitted to override functions in extensions.
// There is also some related code in ViewController.scrollViewDidEndScrollingAnimation
// It's a tad hacky, but we need to call something on it and the function can't be overridden here.
extension ArticleScrolling where Self: ViewController {

    /// Scroll to a given offset in the article
    ///
    /// - Parameters:
    ///   - anchor: The anchor to scroll to. The anchor corresponds to an `id` attribute on a HTML tag in the article.
    ///   - centered: If this parameter is true, the element will be centered in the visible area of the article view after scrolling. If this parameter is false, the element will be at the top of the visible area of the article view.
    ///   - animated: Whether or not to animate the scroll change.
    ///   - completion: A completion that is called when the scroll change is complete. The Boolean passed into the completion is `true` if the point was successfully found and scrolled to or `false` if the point was invalid.
    func scroll(to anchor: String, centered: Bool = false, highlighted: Bool = false, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard !anchor.isEmpty else {
            webView.scrollView.scrollRectToVisible(CGRect(x: 0, y: 1, width: 1, height: 1), animated: animated)
            completion?(true)
            return
        }

        messagingController.prepareForScroll(to: anchor, highlight: highlighted) { (result) in
            assert(Thread.isMainThread)
            switch result {
            case .failure(let error):
                self.showError(error)
                completion?(false)
            case .success:
                // The actual scroll happens via a callback event from the WebView
                // When that event is received, the scrollToAnchorCompletion is called
                let scrollCompletion: ScrollToAnchorCompletion = { (anchor, rect) in
                    let point = CGPoint(x: self.webView.scrollView.contentOffset.x, y: rect.origin.y + self.webView.scrollView.contentOffset.y)
                    self.scroll(to: point, centered: centered, animated: animated, completion: completion)
                }
                self.scrollToAnchorCompletions.insert(scrollCompletion, at: 0)
            }
        }
    }

    /// Scroll to a given offset in the article
    /// - Parameters:
    ///   - offset: The content offset point to scroll to.
    ///   - centered: If this parameter is true, the content offset point will be centered in the visible area of the article view after scrolling. If this parameter is false, the content offset point will be at the top of the visible area of the article view.
    ///   - animated: Whether or not to animate the scroll change.
    ///   - completion: A completion that is called when the scroll change is complete. The Boolean pased into the completion is `true` if the point was successfully found and scrolled to or `false` if the point was invalid.
    func scroll(to offset: CGPoint, centered: Bool = false, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        assert(Thread.isMainThread)
        let scrollView = webView.scrollView
        guard !offset.x.isNaN && !offset.x.isInfinite && !offset.y.isNaN && !offset.y.isInfinite else {
            completion?(false)
            return
        }
        let overlayTop = self.webView.yOffsetHack + self.navigationBar.hiddenHeight
        let adjustmentY: CGFloat
        if centered {
            let overlayBottom = self.webView.scrollView.contentInset.bottom
            let height = self.webView.scrollView.bounds.height
            adjustmentY = -0.5 * (height - overlayTop - overlayBottom)
        } else {
            adjustmentY = overlayTop
        }
        let minYScrollPoint = 0 - scrollView.contentInset.top
        let largestY = scrollView.contentSize.height + scrollView.contentInset.bottom

        /// If there is less than one screen of content, do not let this number be negative, to ensure the ranges below are valid.
        let maxYScrollPoint = max(largestY - scrollView.bounds.height, 0)

        /// If y lies within the last screen, scroll should be to the final full screen.
        let yContentPoint = offset.y + adjustmentY
        let y = (maxYScrollPoint...largestY).contains(yContentPoint) ? maxYScrollPoint : yContentPoint

        guard (minYScrollPoint...maxYScrollPoint).contains(y) else {
            completion?(false)
            return
        }
        let boundedOffset = CGPoint(x: scrollView.contentOffset.x, y: y)
        guard WMFDistanceBetweenPoints(boundedOffset, scrollView.contentOffset) >= 2 else {
            scrollView.flashScrollIndicators()
            completion?(true)
            return
        }
        guard animated else {
            scrollView.setContentOffset(boundedOffset, animated: false)
            completion?(true)
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
        scrollViewAnimationCompletions.insert({ completion?(true) }, at: 0)
        scrollView.setContentOffset(boundedOffset, animated: true)
    }

    func isBoundingClientRectVisible(_ rect: CGRect) -> Bool {
        let scrollView = webView.scrollView
        return rect.minY > scrollView.contentInset.top && rect.maxY < scrollView.bounds.size.height - scrollView.contentInset.bottom
    }
}

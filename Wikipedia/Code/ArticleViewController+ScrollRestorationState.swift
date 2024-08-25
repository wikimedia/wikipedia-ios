import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: - Scroll Restoration State
extension ArticleViewController {
    /// Checks scrollRestorationState and performs the necessary scroll restoration
    func restoreScrollStateIfNecessary() {
        switch scrollRestorationState {
        case .none:
            break
        case .scrollToOffset(let offset, let animated, let attempt, let maxAttempts, let completion):
            scrollRestorationState = .none
            self.scroll(to: CGPoint(x: 0, y: offset), animated: animated) { [weak self] (success) in
                guard !success, attempt < maxAttempts else {
                    completion?(success, attempt >= maxAttempts)
                    return
                }
                self?.scrollRestorationState = .scrollToOffset(offset, animated: animated, attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            }
        case .scrollToPercentage(let verticalOffsetPercentage):
            scrollRestorationState = .none
            webView.scrollView.verticalOffsetPercentage = verticalOffsetPercentage
        case .scrollToAnchor(let anchor, let attempt, let maxAttempts, let completion):
            scrollRestorationState = .none
            self.scroll(to: anchor, animated: true) { [weak self] (success) in
                guard !success, attempt < maxAttempts else {
                    completion?(success, attempt >= maxAttempts)
                    return
                }
                self?.scrollRestorationState = .scrollToAnchor(anchor, attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            }
            
            // HACK: Sometimes the `scroll_to_anchor` message is not triggered from the web view over the JS bridge, even after prepareForScrollToAnchor successfully goes through. This means the completion block above is queued to scrollToAnchorCompletions but never run. We are trying to scroll again here once more after a slight delay in hopes of triggering `scroll_to_anchor` again.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                // This conditional check should target the bug a little closer, since scrollToAnchorCompletions are cleaned out after the last `scroll_to_anchor` message is received. Remaining scrollToAnchorCompletions at this point indicates that likely we're hitting the missing `scroll_to_anchor` message bug.
                if self.scrollToAnchorCompletions.count > 0 {
                    self.scroll(to: anchor, animated: false)
                }
            }
        }
    }
    
    internal func stashOffsetPercentage() {
        let offset = webView.scrollView.verticalOffsetPercentage
        // negative and 0 offsets make small errors in scrolling, allow it to automatically handle those cases
        if offset > 0 {
            scrollRestorationState = .scrollToPercentage(offset)
        }
    }
    
    internal func checkForScrollToAnchor(in response: HTTPURLResponse) {
        guard let fragment = response.url?.fragment else {
            return
        }
        scrollRestorationState = .scrollToAnchor(fragment, attempt: 1)
    }
}

//~~~**DELETE THIS HEADER**~~~

import Foundation

// MARK: ArticleViewController+Article State Restoration

extension ArticleViewController {
    /// Save article scroll position for restoration later
    func saveArticleScrollPosition() {
        getVisibleSection { (sectionId, anchor) in
            assert(Thread.isMainThread)
            self.article.viewedScrollPosition = Double(self.webView.scrollView.contentOffset.y)
            self.article.viewedFragment = anchor
            try? self.article.managedObjectContext?.save()
        }
    }
    
    /// Perform any necessary initial configuration for state restoration
    func setupForStateRestorationIfNecessary() {
        guard isRestoringState else {
            return
        }
        setWebViewHidden(true, animated: false)
    }
    
    /// Translates an article's viewedScrollPosition or viewedFragment values to a scrollRestorationState. These values are saved to the article object when the ArticleVC disappears,the app is backgrounded, or an edit is made and the article is reloaded.
    func assignScrollStateFromArticleFlagsIfNecessary() {
        guard isRestoringState else {
            return
        }
        isRestoringState = false
        let scrollPosition = CGFloat(article.viewedScrollPosition)
        if scrollPosition > 0 {
            scrollRestorationState = .scrollToOffset(scrollPosition, animated: false, completion: { [weak self] success, maxedAttempts in
                if success || maxedAttempts {
                    self?.setWebViewHidden(false, animated: true)
                }
            })
        } else if let fragment = article.viewedFragment {
            scrollRestorationState = .scrollToAnchor(fragment, completion: { [weak self] success, maxedAttempts in
                if success || maxedAttempts {
                    self?.setWebViewHidden(false, animated: true)
                }
            })
        } else {
            setWebViewHidden(false, animated: true)
        }
    }
    
    func setWebViewHidden(_ hidden: Bool, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let block = {
            self.webView.alpha = hidden ? 0 : 1
        }
        guard animated else {
            block()
            completion?(true)
            return
        }
        UIView.animate(withDuration: 0.3, animations: block, completion: completion)
    }
    
    func callLoadCompletionIfNecessary() {
        loadCompletion?()
        loadCompletion = nil
    }
    
}

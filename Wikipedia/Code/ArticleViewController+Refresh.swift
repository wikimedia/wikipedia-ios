import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

import Foundation

// MARK: - ArticleViewController + Refresh

extension ArticleViewController {
    @objc public func refresh() {
        state = .reloading
        if !shouldPerformWebRefreshAfterScrollViewDeceleration {
            updateRefreshOverlay(visible: true)
        }
        shouldPerformWebRefreshAfterScrollViewDeceleration = true
    }
    
    /// Preserves the current scroll position, loads the provided revisionID or waits for a change in etag on the mobile-html response, then refreshes the page and restores the prior scroll position
    internal func waitForNewContentAndRefresh(_ revisionID: UInt64? = nil) {
        showNavigationBar()
        state = .reloading
        saveArticleScrollPosition()
        isRestoringState = true
        setupForStateRestorationIfNecessary()
        // If a revisionID was provided, just load that revision
        if let revisionID = revisionID {
            performWebViewRefresh(revisionID)
            return
        }
        // If no revisionID was provided, wait for the ETag to change
        guard let eTag = currentETag else {
            performWebViewRefresh()
            return
        }
        fetcher.waitForMobileHTMLChange(articleURL: articleURL, eTag: eTag, maxAttempts: 5) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.showError(error, sticky: true)
                    fallthrough
                default:
                    self.performWebViewRefresh()
                }
            }
        }
    }

    internal func performWebViewRefresh(_ revisionID: UInt64? = nil) {

        articleAsLivingDocController.articleDidTriggerPullToRefresh()
        
        switch Configuration.current.environment {
        case .local(let options):
            if options.contains(.localPCS) {
                webView.reloadFromOrigin()
            } else {
                loadPage(cachePolicy: .noPersistentCacheOnError, revisionID: revisionID)
            }
        default:
            loadPage(cachePolicy: .noPersistentCacheOnError, revisionID: revisionID)
        }
    }

    internal func updateRefreshOverlay(visible: Bool, animated: Bool = true) {
        let duration = animated ? (visible ? 0.15 : 0.1) : 0.0
        let alpha: CGFloat = visible ? 0.3 : 0.0
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: [.curveEaseIn], animations: {
            self.refreshOverlay.alpha = alpha
        })
        toolbarController.setToolbarButtons(enabled: !visible)
    }
    
    internal func performWebRefreshAfterScrollViewDecelerationIfNeeded() {
        guard shouldPerformWebRefreshAfterScrollViewDeceleration else {
            return
        }
        webView.scrollView.showsVerticalScrollIndicator = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.performWebViewRefresh()
        })
    }
}

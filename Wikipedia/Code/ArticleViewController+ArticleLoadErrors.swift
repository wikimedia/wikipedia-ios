import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData


// MARK: - Article Load Errors

extension ArticleViewController {
    func handleArticleLoadFailure(with error: Error, showEmptyView: Bool) {
        fakeProgressController.finish()
        if showEmptyView {
            wmf_showEmptyView(of: .articleDidNotLoad, theme: theme, frame: view.bounds)
        }
        showError(error)
        refreshControl.endRefreshing()
        updateRefreshOverlay(visible: false)
    }
    
    func articleLoadDidFail(with error: Error) {
        handleArticleLoadFailure(with: error, showEmptyView: !article.isSaved)
    }
}

extension ArticleViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .reload:
            fallthrough
        case .other:
            setupArticleLoadWaitGroup()
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        switch navigationAction.navigationType {
        case .reload:
            fallthrough
        case .other:
            setupArticleLoadWaitGroup()
            decisionHandler(.allow, preferences)
        default:
            decisionHandler(.cancel, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        defer {
            decisionHandler(.allow)
        }
        guard let response = navigationResponse.response as? HTTPURLResponse else {
            return
        }
        currentETag = response.allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String
        checkForScrollToAnchor(in: response)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        articleLoadDidFail(with: error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        articleLoadDidFail(with: error)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // On process did terminate, the WKWebView goes blank
        // Re-load the content in this case to show it again
        webView.reload()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if shouldPerformWebRefreshAfterScrollViewDeceleration {
            updateRefreshOverlay(visible: false)
            webView.scrollView.showsVerticalScrollIndicator = true
            shouldPerformWebRefreshAfterScrollViewDeceleration = false
        }
    }
}

extension ViewController { // Putting extension on ViewController rather than ArticleVC allows for re-use by EditPreviewVC

    var articleMargins: UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: articleHorizontalMargin, bottom: 0, right: articleHorizontalMargin)
    }

    var articleHorizontalMargin: CGFloat {
        let viewForCalculation: UIView = navigationController?.view ?? view

        if let tableOfContentsVC = (self as? ArticleViewController)?.tableOfContentsController.viewController, tableOfContentsVC.isVisible {
            // full width
            return viewForCalculation.layoutMargins.left
        } else {
            // If (is EditPreviewVC) or (is TOC OffScreen) then use readableContentGuide to make text inset from screen edges.
            // Since readableContentGuide has no effect on compact width, both paths of this `if` statement result in an identical result for smaller screens.
            return viewForCalculation.readableContentGuide.layoutFrame.minX
        }
    }
}



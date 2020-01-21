extension ArticleViewController : TableOfContentsViewControllerDelegate {
    
    func hideTableOfContents() {
        tableOfContentsDisplayController.hide(animated: true)
        toolbarController.update()
    }
    
    func showTableOfContents() {
        tableOfContentsDisplayController.show(animated: true)
        toolbarController.update()
    }
    
    var tableOfContentsSemanticContentAttribute: UISemanticContentAttribute {
        return MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleURL.wmf_language)
    }
    
    func tableOfContentsControllerWillDisplay(_ controller: TableOfContentsViewController) {
        //        webViewController.getCurrentVisibleSectionCompletion { (section, error) in
        //            if let item: TableOfContentsItem = section {
        //                self.tableOfContentsViewController!.selectAndScrollToItem(item, animated: false)
        //            } else {
        //                self.webViewController.getCurrentVisibleFooterIndexCompletion { (footerIndex, error) in
        //                    if let index = footerIndex {
        //                        self.tableOfContentsViewController!.selectAndScrollToFooterItem(atIndex: index.intValue, animated: false)
        //                    }
        //                }
        //            }
        //        }
    }
    
    public func tableOfContentsController(_ controller: TableOfContentsViewController, didSelectItem item: TableOfContentsItem) {
        switch tableOfContentsViewController.displayMode {
        case .inline:
            scroll(to: item.anchor, animated: true)
            dispatchOnMainQueueAfterDelayInSeconds(1) {
                self.webView.wmf_accessibilityCursor(toFragment: item.anchor)
            }
        case .modal:
            tableOfContentsViewController.isVisible = false
            scroll(to: item.anchor, animated: true)
            var dismissVCCompletionHandler: (() -> Void)?
            // HAX: webview has issues scrolling when browser view is out of bounds, disable animation if needed
            dismissVCCompletionHandler = {
                // HAX: This is terrible, but iOS events not under our control would steal our focus if we didn't wait long enough here and due to problems in UIWebView, we cannot work around it either.
                dispatchOnMainQueueAfterDelayInSeconds(1) {
                    self.webView.wmf_accessibilityCursor(toFragment: item.anchor)
                }
            }
            
            // Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
            dispatchOnMainQueueAfterDelayInSeconds(0.15) {
                self.dismiss(animated: true, completion: dismissVCCompletionHandler)
            }
        }
    }

    
    public func tableOfContentsControllerDidCancel(_ controller: TableOfContentsViewController) {
        tableOfContentsDisplayController.hide(animated: true)
    }

    public var tableOfContentsArticleLanguageURL: URL? {
        let articleNSURL = self.articleURL as NSURL
        if articleNSURL.wmf_isNonStandardURL {
            return NSURL.wmf_URL(withDefaultSiteAndlanguage: "en")
        } else {
            return articleNSURL.wmf_site
        }
    }
}

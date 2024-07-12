import CocoaLumberjackSwift

extension ArticleViewController : ArticleTableOfContentsDisplayControllerDelegate {
    func getVisibleSection(with completion: @escaping (_ sectionID: Int, _ anchor: String) -> Void) {
        webView.evaluateJavaScript("window.wmf.elementLocation.getFirstOnScreenSection(\(navigationBar.visibleHeight))") { (result, error) in
            guard
                let info = result as? [String: Any],
                let sectionId = info["id"] as? Int,
                let anchor = info["anchor"] as? String
            else {
                DDLogWarn("Error getting first on screen section: \(String(describing: error))")
                completion(-1, "")
                return
            }
            completion(sectionId, anchor)
        }
    }
    
    func hideTableOfContents() {
        tableOfContentsController.hide(animated: true)
        toolbarController.update()
        if tableOfContentsController.viewController.displayMode == .inline {
            updateArticleMargins()
        }
    }
    
    func showTableOfContents() {
        tableOfContentsController.show(animated: true)
        toolbarController.update()
        if tableOfContentsController.viewController.displayMode == .inline {
            updateArticleMargins()
        }
    }
    
    var tableOfContentsDisplaySide: TableOfContentsDisplaySide {
        return tableOfContentsSemanticContentAttribute == .forceRightToLeft ? .right : .left
    }
    
    var tableOfContentsSemanticContentAttribute: UISemanticContentAttribute {
        return MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: articleURL.wmf_contentLanguageCode)
    }
    
    func tableOfContentsDisplayControllerDidRecreateTableOfContentsViewController() {
        updateTableOfContentsInsets()
    }
    
    func tableOfContentsControllerWillDisplay(_ controller: TableOfContentsViewController) {
        
    }
    
    public func tableOfContentsController(_ controller: TableOfContentsViewController, didSelectItem item: TableOfContentsItem) {
        switch tableOfContentsController.viewController.displayMode {
        case .inline:
            scroll(to: item.anchor, animated: true)
            dispatchOnMainQueueAfterDelayInSeconds(1) {
                self.webView.wmf_accessibilityCursor(toFragment: item.anchor)
            }
        case .modal:
            scroll(to: item.anchor, animated: true)
            // Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
            dispatchOnMainQueueAfterDelayInSeconds(0.15) {
                self.hideTableOfContents()
                // HAX: This is terrible, but iOS events not under our control would steal our focus if we didn't wait long enough here and due to problems in UIWebView, we cannot work around it either.
                dispatchOnMainQueueAfterDelayInSeconds(1.5) {
                    self.webView.wmf_accessibilityCursor(toFragment: item.anchor)
                }
            }
        }

        article.viewedFragment = item.anchor
    }

    public func tableOfContentsControllerDidCancel(_ controller: TableOfContentsViewController) {
        tableOfContentsController.hide(animated: true)
    }

    public var tableOfContentsArticleLanguageURL: URL? {
        let articleNSURL = self.articleURL as NSURL
        if articleNSURL.wmf_isNonStandardURL {
            return NSURL.wmf_URL(withDefaultSiteAndLanguageCode: "en")
        } else {
            return articleNSURL.wmf_site
        }
    }
}

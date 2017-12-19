import Foundation

extension WMFArticleViewController : WMFTableOfContentsViewControllerDelegate {

    public func tableOfContentsControllerWillDisplay(_ controller: WMFTableOfContentsViewController){
        webViewController.getCurrentVisibleSectionCompletion { (section, error) in
            if let item: TableOfContentsItem = section {
                self.tableOfContentsViewController!.selectAndScrollToItem(item, animated: false)
            } else {
                self.webViewController.getCurrentVisibleFooterIndexCompletion { (footerIndex, error) in
                    if let index = footerIndex {
                        self.tableOfContentsViewController!.selectAndScrollToFooterItem(atIndex: index.intValue, animated: false)
                    }
                }
            }
        }
    }
    
    public func tableOfContentsController(_ controller: WMFTableOfContentsViewController,
                                          didSelectItem item: TableOfContentsItem) {

        switch tableOfContentsDisplayMode {
        case .inline:
            if let section = item as? MWKSection {
                self.currentSection = section
                self.sectionToRestoreScrollOffset = section
                self.webViewController.scroll(to: section, animated: true)
                dispatchOnMainQueueAfterDelayInSeconds(1) {
                    self.webViewController.accessibilityCursor(to: section)
                }
            } else {
                scrollToFooterSection(for: item)
            }
        case .modal:
            fallthrough
        default:
            tableOfContentsDisplayState = .modalHidden
            var dismissVCCompletionHandler: (() -> Void)?
            if let section = item as? MWKSection {
                self.currentSection = section
                // HAX: webview has issues scrolling when browser view is out of bounds, disable animation if needed
                self.webViewController.scroll(to: section, animated: true)
                dismissVCCompletionHandler = {
                    // HAX: This is terrible, but iOS events not under our control would steal our focus if we didn't wait long enough here and due to problems in UIWebView, we cannot work around it either.
                    dispatchOnMainQueueAfterDelayInSeconds(1) {
                        self.webViewController.accessibilityCursor(to: section)
                    }
                }
            } else {
                scrollToFooterSection(for: item)
            }
            
            // Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
            dispatchOnMainQueueAfterDelayInSeconds(0.25) {
                self.dismiss(animated: true, completion: dismissVCCompletionHandler)
            }
        }        
    }

    private func scrollToFooterSection(for item: TableOfContentsItem) {
        switch item {
        case is TableOfContentsAboutThisArticleItem:
            self.webViewController.scroll(toFragment: "pagelib_footer_container_menu", animated: true)
        case is TableOfContentsReadMoreItem:
            self.webViewController.scroll(toFragment: "pagelib_footer_container_readmore", animated: true)
        default:
            assertionFailure("Unsupported selection of TOC item \(item)")
            break
        }
    }
    
    public func tableOfContentsControllerDidCancel(_ controller: WMFTableOfContentsViewController) {
        dismiss(animated: true, completion: nil)
    }

    public func tableOfContentsArticleLanguageURL() -> URL? {
        let articleNSURL = self.articleURL as NSURL
        if(articleNSURL.wmf_isNonStandardURL){
            return NSURL.wmf_URL(withDefaultSiteAndlanguage: "en")
        }else{
            return articleNSURL.wmf_site
        }
    }
    
    public func tableOfContentsDisplayModeIsModal() -> Bool {
        return self.tableOfContentsDisplayMode == .modal;
    }
}

extension WMFArticleViewController {

    /**
     Create ToC items.

     - note: This must be done in Swift because `WMFTableOfContentsViewControllerDelegate` is not an ObjC protocol,
     and therefore cannot be referenced in Objective-C.

     - returns: sections of the ToC.
     */
    func createTableOfContentsSections() -> [TableOfContentsItem]? {
        // HAX: need to forcibly downcast each section object to our protocol type. yay objc/swift interop!
        return hasTableOfContents() ? article?.sections?.entries.map() { $0 as! TableOfContentsItem } : nil
    }

    /**
    Create a new instance of `WMFTableOfContentsViewController` which is configured to be used with the receiver.
    */
    @objc public func createTableOfContentsViewControllerIfNeeded() {
        if let items = createTableOfContentsSections() {
            let semanticContentAttribute:UISemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: article?.url.wmf_language)
            self.tableOfContentsViewController = WMFTableOfContentsViewController(presentingViewController: tableOfContentsDisplayMode == .modal ? self : nil , items: items, delegate: self, semanticContentAttribute: semanticContentAttribute, theme: self.theme)
        }
    }

    /**
     Append a read more section to the table of contents.
     */
    @objc public func appendItemsToTableOfContentsIncludingAboutThisArticle(_ includeAbout: Bool, includeReadMore: Bool) {
        assert(self.tableOfContentsViewController != nil, "Attempting to add read more when toc is nil")
        guard let tvc = self.tableOfContentsViewController else { return; }

        if var items = createTableOfContentsSections() {
            if (includeAbout) {
                items.append(TableOfContentsAboutThisArticleItem(url: self.articleURL))
            }
            if (includeReadMore) {
                items.append(TableOfContentsReadMoreItem(url: self.articleURL))
            }
            tvc.items = items
        }
    }
    
    func backgroundView() -> UIVisualEffectView {
        let view = UIVisualEffectView(frame: CGRect.zero)
        view.autoresizingMask = .flexibleWidth
        view.effect = UIBlurEffect(style: self.theme.blurEffectStyle)
        view.alpha = 0.0
        return view
    }

    @objc public func selectAndScrollToTableOfContentsItemForSection(_ section: MWKSection, animated: Bool) {
        tableOfContentsViewController?.selectAndScrollToItem(section, animated: animated)
    }
    
    @objc public func selectAndScrollToTableOfContentsFooterItemAtIndex(_ index: Int, animated: Bool) {
        tableOfContentsViewController?.selectAndScrollToFooterItem(atIndex: index, animated: animated)
    }
}

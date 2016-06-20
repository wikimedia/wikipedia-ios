
import Foundation

extension WMFArticleViewController : WMFTableOfContentsViewControllerDelegate {

    public func tableOfContentsControllerWillDisplay(controller: WMFTableOfContentsViewController){
        webViewController.getCurrentVisibleSectionCompletion({(section: MWKSection?, error: NSError?) -> Void in
            if let item: TableOfContentsItem = section {
                self.tableOfContentsViewController!.selectAndScrollToItem(item, animated: false)
            } else if let footerIndex: WMFArticleFooterViewIndex = WMFArticleFooterViewIndex(rawValue: self.webViewController.visibleFooterIndex()) {
                switch footerIndex {
                case .ReadMore:
                    self.tableOfContentsViewController!.selectAndScrollToItem(TableOfContentsReadMoreItem(site: self.articleTitle.site), animated: false)
                case .AboutThisArticle:
                    self.tableOfContentsViewController!.selectAndScrollToItem(TableOfContentsAboutThisArticleItem(site: self.articleTitle.site), animated: false)
                }
            } else {
                assertionFailure("Couldn't find current position of user at current offset!")
            }
        })
    }

    public func tableOfContentsController(controller: WMFTableOfContentsViewController,
                                          didSelectItem item: TableOfContentsItem) {
        var dismissVCCompletionHandler: (() -> Void)?
        if let section = item as? MWKSection {
            // HAX: webview has issues scrolling when browser view is out of bounds, disable animation if needed
            self.webViewController.scrollToSection(section, animated: true)
            dismissVCCompletionHandler = {
                // HAX: This is terrible, but iOS events not under our control would steal our focus if we didn't wait long enough here and due to problems in UIWebView, we cannot work around it either.
                dispatchOnMainQueueAfterDelayInSeconds(1) {
                    self.webViewController.accessibilityCursorToSection(section)
                }
            }
        } else if let footerItem = item as? TableOfContentsFooterItem {
            let footerIndex = UInt(footerItem.footerViewIndex.rawValue)
            self.webViewController.scrollToFooterAtIndex(footerIndex)
            dismissVCCompletionHandler = {
                self.webViewController.accessibilityCursorToFooterAtIndex(footerIndex)
            }
        } else {
            assertionFailure("Unsupported selection of TOC item \(item)")
        }

        // Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
        dispatchOnMainQueueAfterDelayInSeconds(0.25) {
            self.dismissViewControllerAnimated(true, completion: dismissVCCompletionHandler)
        }
    }

    public func tableOfContentsControllerDidCancel(controller: WMFTableOfContentsViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    public func tableOfContentsArticleSite() -> MWKSite {
        if(self.articleTitle.isNonStandardTitle()){
            return MWKSite.init(language: "en")
        }else{
            return self.articleTitle.site
        }
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
    public func createTableOfContentsViewControllerIfNeeded() {
        if let items = createTableOfContentsSections() {
            self.tableOfContentsViewController = WMFTableOfContentsViewController(presentingViewController: self, items: items, delegate: self)
        }
    }

    /**
     Append a read more section to the table of contents.
     */
    public func appendItemsToTableOfContentsIncludingAboutThisArticle(includeAbout: Bool, includeReadMore: Bool) {
        assert(self.tableOfContentsViewController != nil, "Attempting to add read more when toc is nil")
        guard let tvc = self.tableOfContentsViewController else { return; }

        if var items = createTableOfContentsSections() {
            if (includeAbout) {
                items.append(TableOfContentsAboutThisArticleItem(site: self.articleTitle.site))
            }
            if (includeReadMore) {
                items.append(TableOfContentsReadMoreItem(site: self.articleTitle.site))
            }
            tvc.items = items
        }
    }

    public func showTableOfContents() {
        presentViewController(self.tableOfContentsViewController!, animated: true, completion: nil)

    }
    
    func backgroundView() -> UIVisualEffectView {
        let view = UIVisualEffectView(frame: CGRectZero)
        view.autoresizingMask = .FlexibleWidth
        view.effect = UIBlurEffect(style: .Light)
        view.alpha = 0.0
        return view
    }
    
    class func registerTweak(){
        #if DEBUG
            let tweak = FBTweak(identifier: "Always Peek ToC")
            tweak.name = "Always Peek ToC"
            tweak.defaultValue = false
            
            let collection = FBTweakCollection(name: "Table of Contents");
            collection.addTweak(tweak)
            
            let store = FBTweakStore.sharedInstance()
            
            if let category = store.tweakCategoryWithName("Article") {
                category.addTweakCollection(collection);
            }else{
                let category = FBTweakCategory(name: "Article")
                store.addTweakCategory(category)
                category.addTweakCollection(collection);
            }
        #endif
    }
    
    func shouldPeek() -> Bool {
        
        #if DEBUG
            let store = FBTweakStore.sharedInstance()
            let category = store.tweakCategoryWithName("Article")
            let collection = category.tweakCollectionWithName("Table of Contents")
            let tweak = collection.tweakWithIdentifier("Always Peek ToC")
            if tweak.currentValue as? Bool == true {
                return true
            }
        #endif
        
        return !NSUserDefaults.standardUserDefaults().wmf_didPeekTableOfContents()
    }

    public func peekTableOfContentsIfNeccesary() {
        guard self.navigationController != nil else{
            return
        }
        guard let toc = self.tableOfContentsViewController else{
            return
        }
        guard shouldPeek() == true else{
            return
        }

        let bg = backgroundView()
        
        let containerBounds = self.navigationController!.view.bounds
        bg.frame = containerBounds
        self.navigationController!.view!.addSubview(bg)

        let tocWidth: CGFloat = 300.0
        let peekWidth = (containerBounds.width * 0.3) < tocWidth ? containerBounds.width * 0.3 : tocWidth
        
        var onscreen = containerBounds
        onscreen.size.width = tocWidth
        var offscreen = onscreen
        
        if UIApplication.sharedApplication().wmf_tocShouldBeOnLeft {
            offscreen.origin.x -= offscreen.width
            onscreen.origin.x = offscreen.origin.x + peekWidth
        }else{
            onscreen.origin.x = containerBounds.width - peekWidth
            offscreen.origin.x = containerBounds.width
        }
        
        toc.view.frame = offscreen
        toc.view.layer.shadowOpacity = 0.25
        toc.view.layer.shadowRadius = 4.0
        toc.view.layer.shadowOffset = CGSizeZero
        
        self.navigationController!.view!.addSubview(toc.view)
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            bg.alpha = 1.0;
            toc.view.frame = onscreen
            
            }) { (completed) in
                UIView.animateWithDuration(0.2, delay: 0.7, options: .CurveEaseInOut, animations: {
                    bg.alpha = 0.0;
                    toc.view.frame = offscreen
                    }, completion: { (completed) in
                        bg.removeFromSuperview()
                        toc.view.removeFromSuperview()
                        NSUserDefaults.standardUserDefaults().wmf_setDidPeekTableOfContents(true)
                })
        }
    }
}

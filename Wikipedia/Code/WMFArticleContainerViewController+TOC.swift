
import Foundation
import BlocksKit

extension WMFArticleViewController : WMFTableOfContentsViewControllerDelegate {

    public func tableOfContentsControllerWillDisplay(controller: WMFTableOfContentsViewController){
        if let item: TableOfContentsItem = webViewController.currentVisibleSection() {
            tableOfContentsViewController!.selectAndScrollToItem(item, animated: false)
        } else if let footerIndex: WMFArticleFooterViewIndex = WMFArticleFooterViewIndex(rawValue: webViewController.visibleFooterIndex()) {
            switch footerIndex {
            case .ReadMore:
                tableOfContentsViewController!.selectAndScrollToItem(TableOfContentsReadMoreItem(site: self.articleTitle.site), animated: false)
            }
        } else {
            assertionFailure("Couldn't find current position of user at current offset!")
        }
    }

    public func tableOfContentsController(controller: WMFTableOfContentsViewController,
                                          didSelectItem item: TableOfContentsItem) {
        var dismissVCCompletionHandler: (() -> Void)?
        if let section = item as? MWKSection {
            // HAX: webview has issues scrolling when browser view is out of bounds, disable animation if needed
            self.webViewController.scrollToSection(section, animated: self.webViewController.isWebContentVisible)
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
        return self.articleTitle.site
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
    public func appendReadMoreTableOfContentsItemIfNeeded() {
        assert(self.tableOfContentsViewController != nil, "Attempting to add read more when toc is nil")
        guard let tvc = self.tableOfContentsViewController
              where !tvc.items.contains({ (item: TableOfContentsItem) in item.dynamicType == TableOfContentsReadMoreItem.self })
              else { return }
        if var items = createTableOfContentsSections() {
            items.append(TableOfContentsReadMoreItem(site: self.articleTitle.site))
            tvc.items = items
        }
    }

    public func showTableOfContents() {
        presentViewController(self.tableOfContentsViewController!, animated: true, completion: nil)

    }
    
    func backgroundView() -> UIVisualEffectView {
        let view = UIVisualEffectView(frame: CGRectZero)
        view.autoresizingMask = .FlexibleWidth
        view.effect = UIBlurEffect(style: .Dark)
        view.alpha = 0.0
        return view
    }

    public func peekTableOfContentsIfNeccesary() {
        guard let toc = self.tableOfContentsViewController else{
            return
        }
        guard NSUserDefaults.standardUserDefaults().wmf_didPeekTableOfContents() == false else{
            return
        }

        let bg = backgroundView()
        
        let containerBounds = self.navigationController!.view.bounds
        bg.frame = containerBounds
        self.navigationController!.view!.addSubview(bg)

        let maxToCWidth: CGFloat = 300.0
        let peekWidth = (containerBounds.width * 0.3) < maxToCWidth ? containerBounds.width * 0.3 : maxToCWidth
        let tocWidth = (containerBounds.width * 0.4) < maxToCWidth ? containerBounds.width * 0.4 : maxToCWidth
        
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
        self.navigationController!.view!.addSubview(toc.view)
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            bg.alpha = 0.8;
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

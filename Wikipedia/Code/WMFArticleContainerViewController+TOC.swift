
import Foundation
import BlocksKit

extension WMFArticleContainerViewController : WMFTableOfContentsViewControllerDelegate {
    
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
                                            
        if let section = item as? MWKSection {
            // HAX: webview has issues scrolling when browser view is out of bounds, disable animation if needed
            self.webViewController.scrollToSection(section, animated: self.webViewController.isWebContentVisible)
        } else if let footerItem = item as? TableOfContentsFooterItem {
            self.webViewController.scrollToFooterAtIndex(UInt(footerItem.footerViewIndex.rawValue))
        } else {
            assertionFailure("Unsupported selection of TOC item \(item)")
        }
        
        // Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
        dispatchOnMainQueueAfterDelayInSeconds(0.25) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    public func tableOfContentsControllerDidCancel(controller: WMFTableOfContentsViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    public func tableOfContentsArticleSite() -> MWKSite {
        return self.articleTitle.site
    }
}

extension WMFArticleContainerViewController {
    
    /**
     Create ToC items.
     
     - note: This must be done in Swift because `WMFTableOfContentsViewControllerDelegate` is not an ObjC protocol,
     and therefore cannot be referenced in Objective-C.
     
     - returns: sections of the ToC.
     */
    func createTableOfContentsSections() -> [TableOfContentsItem]?{
        if let sections = self.article?.sections {
            // HAX: need to forcibly downcast each section object to our protocol type. yay objc/swift interop!
            let items = sections.entries.map() { $0 as! TableOfContentsItem }
            return items
        }else{
            
            return nil
        }
    }
    
    /**
    Create a new instance of `WMFTableOfContentsViewController` which is configured to be used with the receiver.
    */
    public func createTableOfContentsViewController() {
        if let items = createTableOfContentsSections() {
            self.tableOfContentsViewController = WMFTableOfContentsViewController(presentingViewController: self, items: items, delegate: self)
        }
    }

    /**
     Append a read more section to the table of contents.
     */
    public func appendReadMoreTableOfContentsItem() {
        assert(self.tableOfContentsViewController != nil, "Attempting to add read more when toc is nil")
        guard let tvc = self.tableOfContentsViewController else{
            return
        }
        
        if var items = createTableOfContentsSections() {
            items.append(TableOfContentsReadMoreItem(site: self.articleTitle.site))
            tvc.items = items
        }
    }

    public func didTapTableOfContentsButton(sender: AnyObject?) {
        presentViewController(self.tableOfContentsViewController!, animated: true, completion: nil)

    }
}

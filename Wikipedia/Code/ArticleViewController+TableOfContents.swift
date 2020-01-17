enum TableOfContentsDisplayMode {
    case inline
    case modal
}

enum TableOfContentsDisplaySide {
    case left
    case right
}

extension ArticleViewController {
    
    func showTableOfContents() {
        themesPresenter.dismissReadingThemesPopoverIfActive(from: self)
        
        guard let tocVC = tableOfContents.viewController else {
            return
        }
        
        tocVC.displaySide = tableOfContents.displaySide
        tocVC.displayMode = tableOfContents.displayMode
        
        tableOfContents.isVisible = true

        switch tableOfContents.displayMode {
        case .inline:
            UserDefaults.wmf.wmf_setTableOfContentsIsVisibleInline(true)
            updateTableOfContentsLayout(animated: true)
        case .modal:
            guard presentedViewController == nil else {
                break
            }
            present(tocVC, animated: true)
        }
        toolbarController.update()
    }
    
    func updateTableOfContents(with traitCollection: UITraitCollection) {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        tableOfContents.displaySide = traitCollection.layoutDirection == .rightToLeft ? .right : .left
        tableOfContents.displayMode = isCompact ? .modal : .inline
        tableOfContents.isUpdatingSectionOnScroll = tableOfContents.displayMode == .inline
        updateTableOfContentsInsets()
        setupTableOfContentsViewController()
    }
    
    func updateTableOfContentsInsets() {
//        UIScrollView *scrollView = self.tableOfContentsViewController.tableView;
//        BOOL wasAtTop = scrollView.contentOffset.y == 0 - scrollView.contentInset.top;
//        if (self.tableOfContentsDisplayMode == WMFTableOfContentsDisplayModeInline) {
//            scrollView.contentInset = self.scrollView.contentInset;
//            scrollView.scrollIndicatorInsets = self.scrollView.scrollIndicatorInsets;
//        } else {
//            CGFloat top = self.view.safeAreaInsets.top;
//            CGFloat bottom = self.view.safeAreaInsets.bottom;
//            scrollView.contentInset = UIEdgeInsetsMake(top, 0, bottom, 0);
//            scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(top, 0, bottom, 0);
//        }
//        if (wasAtTop) {
//            scrollView.contentOffset = CGPointMake(0, 0 - scrollView.contentInset.top);
//        }
    }
    
    func setupTableOfContentsViewController() {
        switch tableOfContents.displayMode {
        case .inline:
            if tableOfContents.viewController?.parent != self {
                if presentedViewController == tableOfContents.viewController {
                    tableOfContents.viewController?.dismiss(animated: false)
                }
            }
            tableOfContents.viewController = nil
            createTableOfContentsViewControllerIfNeeded()
            tableOfContents.viewController?.displayMode = tableOfContents.displayMode
            tableOfContents.viewController?.displaySide = tableOfContents.displaySide
            tableOfContents.isVisible = tableOfContents.viewController == nil
            if tableOfContents.isVisible, let tocVC = tableOfContents.viewController {
                addChild(tocVC)
                view.insertSubview(tocVC.view, aboveSubview: webView)
                tocVC.didMove(toParent: self)
                view.insertSubview(tableOfContents.separatorView, aboveSubview: tocVC.view)
            }
            let closeGR = UISwipeGestureRecognizer(target: self, action: #selector(handleTableOfContentsCloseGesture))
            switch tableOfContents.displaySide {
            case .left:
                closeGR.direction = .left
            case .right:
                closeGR.direction = .right
            }
            tableOfContents.viewController?.view.addGestureRecognizer(closeGR)
            tableOfContents.closeGestureRecognizer = closeGR
        case .modal:
            if let tocVC = tableOfContents.viewController, tocVC.parent == self {
                tocVC.willMove(toParent: nil)
                tocVC.view.removeFromSuperview()
                tocVC.removeFromParent()
                tableOfContents.separatorView.removeFromSuperview()
                tableOfContents.viewController = nil
            }
            createTableOfContentsViewControllerIfNeeded()
            tableOfContents.viewController?.displayMode = tableOfContents.displayMode
            tableOfContents.viewController?.displaySide = tableOfContents.displaySide
        }
        toolbarController.update()
        updateTableOfContentsInsets()
    }
    
    func updateTableOfContentsLayout(animated: Bool) {
        
    }
}


extension ArticleViewController : TableOfContentsViewControllerDelegate {
    public func tableOfContentsControllerWillDisplay(_ controller: TableOfContentsViewController){
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

//        switch tableOfContentsDisplayMode {
//        case .inline:
//            if let section = item as? MWKSection {
//                self.currentSection = section
//                self.anchorToRestoreScrollOffset = section.anchor
//                self.scroll(toAnchor: section.anchor, animated: true)
//                dispatchOnMainQueueAfterDelayInSeconds(1) {
//                    self.webViewController.accessibilityCursor(to: section)
//                }
//            } else {
//                scrollToFooterSection(for: item)
//            }
//        case .modal:
//            fallthrough
//        default:
//            tableOfContentsDisplayState = .modalHidden
//            var dismissVCCompletionHandler: (() -> Void)?
//            if let section = item as? MWKSection {
//                self.currentSection = section
//                // HAX: webview has issues scrolling when browser view is out of bounds, disable animation if needed
//                self.scroll(toAnchor: section.anchor, animated: true)
//                dismissVCCompletionHandler = {
//                    // HAX: This is terrible, but iOS events not under our control would steal our focus if we didn't wait long enough here and due to problems in UIWebView, we cannot work around it either.
//                    dispatchOnMainQueueAfterDelayInSeconds(1) {
//                        self.webViewController.accessibilityCursor(to: section)
//                    }
//                }
//            } else {
//                scrollToFooterSection(for: item)
//            }
//
//            // Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
//            dispatchOnMainQueueAfterDelayInSeconds(0.15) {
//                self.dismiss(animated: true, completion: dismissVCCompletionHandler)
//            }
//        }
    }

    private func scrollToFooterSection(for item: TableOfContentsItem) {
//        switch item {
//        case is TableOfContentsAboutThisArticleItem:
//            self.scroll(toAnchor: "pagelib_footer_container_menu", animated: true)
//        case is TableOfContentsReadMoreItem:
//            self.scroll(toAnchor: "pagelib_footer_container_readmore", animated: true)
//        default:
//            assertionFailure("Unsupported selection of TOC item \(item)")
//            break
//        }
    }
    
    public func tableOfContentsControllerDidCancel(_ controller: TableOfContentsViewController) {
        dismiss(animated: true)
    }

    public var tableOfContentsArticleLanguageURL: URL? {
        let articleNSURL = self.articleURL as NSURL
        if articleNSURL.wmf_isNonStandardURL {
            return NSURL.wmf_URL(withDefaultSiteAndlanguage: "en")
        } else {
            return articleNSURL.wmf_site
        }
    }
    
    public var tableOfContentsDisplayModeIsModal: Bool {
        return tableOfContents.displayMode == .modal
    }
}


extension ArticleViewController {

    @objc func handleTableOfContentsCloseGesture(_ swipeGestureRecoginzer: UIGestureRecognizer) {
        
    }
    /**
     Create ToC items.

     - note: This must be done in Swift because `WMFTableOfContentsViewControllerDelegate` is not an ObjC protocol,
     and therefore cannot be referenced in Objective-C.

     - returns: sections of the ToC.
     */
    func createTableOfContentsSections() -> [TableOfContentsItem]? {
        return nil
        // HAX: need to forcibly downcast each section object to our protocol type. yay objc/swift interop!
        //return hasTableOfContents() ? article?.sections?.entries.map() { $0 as! TableOfContentsItem } : nil
    }

    /**
    Create a new instance of `WMFTableOfContentsViewController` which is configured to be used with the receiver.
    */
    public func createTableOfContentsViewControllerIfNeeded() {
        let semanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleURL.wmf_language)
        tableOfContents.viewController = TableOfContentsViewController(presentingViewController: tableOfContents.displayMode == .modal ? self : nil, items: tableOfContents.items, delegate: self, semanticContentAttribute: semanticContentAttribute, theme: theme)
    }
    
    var backgroundView: UIVisualEffectView {
        let view = UIVisualEffectView(frame: CGRect.zero)
        view.autoresizingMask = .flexibleWidth
        view.effect = UIBlurEffect(style: self.theme.blurEffectStyle)
        view.alpha = 0.0
        return view
    }
}

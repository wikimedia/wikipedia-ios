enum TableOfContentsDisplayMode {
    case inline
    case modal
}

enum TableOfContentsDisplaySide {
    case left
    case right
}

private extension ArticleViewController {
    func updateTableOfContents(with traitCollection: UITraitCollection) {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        tableOfContentsDisplaySide = traitCollection.layoutDirection == .rightToLeft ? .right : .left
        tableOfContentsDisplayMode = isCompact ? .modal : .inline
        isUpdatingTableOfContentsSectionOnScroll = tableOfContentsDisplayMode == .inline
        updateTableOfContentsInsets()
        setupTableOfContentsViewController()
    }
    
    func updateTableOfContentsInsets() {
        
    }
    
    func setupTableOfContentsViewController() {
        switch tableOfContentsDisplayMode {
        case .inline:
            if tableOfContentsViewController?.parent != self {
                if presentedViewController == tableOfContentsViewController {
                    tableOfContentsViewController?.dismiss(animated: false)
                }
            }
            tableOfContentsViewController = nil
            createTableOfContentsViewControllerIfNeeded()
            tableOfContentsViewController?.displayMode = tableOfContentsDisplayMode
            tableOfContentsViewController?.displaySide = tableOfContentsDisplaySide
            isTableOfContentsVisible = tableOfContentsViewController == nil
            if isTableOfContentsVisible, let tocVC = tableOfContentsViewController {
                addChild(tocVC)
                view.insertSubview(tocVC.view, aboveSubview: webView)
                tableOfContentsViewController?.didMove(toParent: self)
                view.insertSubview(tableOfContentsSeparatorView, aboveSubview: tocVC.view)
            }

        case .modal:
            break
        }
//        switch (self.tableOfContentsDisplayMode) {
//]
//                           [self addChildViewController:self.tableOfContentsViewController];
//                           [self.view insertSubview:self.tableOfContentsViewController.view aboveSubview:self.webViewController.view];
//                           [self.tableOfContentsViewController didMoveToParentViewController:self];
//
//                           [self.view insertSubview:self.tableOfContentsSeparatorView aboveSubview:self.tableOfContentsViewController.view];
//
//                           self.tableOfContentsCloseGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableOfContentsCloseGesture:)];
//                           UISwipeGestureRecognizerDirection closeDirection;
//                           switch (self.tableOfContentsDisplaySide) {
//                               case TableOfContentsDisplaySideRight:
//                                   closeDirection = UISwipeGestureRecognizerDirectionRight;
//                                   break;
//                               case TableOfContentsDisplaySideLeft:
//                               default:
//                                   closeDirection = UISwipeGestureRecognizerDirectionLeft;
//                                   break;
//                           }
//                           self.tableOfContentsCloseGestureRecognizer.direction = closeDirection;
//                           [self.tableOfContentsViewController.view addGestureRecognizer:self.tableOfContentsCloseGestureRecognizer];
//                       }
//                   }
//               } break;
//               default:
//               case TableOfContentsDisplayModeModal: {
//                   if (self.tableOfContentsViewController.parentViewController == self) {
//                       [self.tableOfContentsViewController willMoveToParentViewController:nil];
//                       [self.tableOfContentsViewController.view removeFromSuperview];
//                       [self.tableOfContentsViewController removeFromParentViewController];
//                       [self.tableOfContentsSeparatorView removeFromSuperview];
//                       self.tableOfContentsViewController = nil;
//                   }
//                   [self createTableOfContentsViewControllerIfNeeded];
//                   self.tableOfContentsViewController.displayMode = self.tableOfContentsDisplayMode;
//                   self.tableOfContentsViewController.displaySide = self.tableOfContentsDisplaySide;
//
//                   switch (self.tableOfContentsDisplayState) {
//                       case TableOfContentsDisplayStateInlineVisible:
//                           self.tableOfContentsDisplayState = TableOfContentsDisplayStateModalVisible;
//                           [self showTableOfContents:self];
//                           break;
//                       case TableOfContentsDisplayStateInlineHidden:
//                       default:
//                           self.tableOfContentsDisplayState = TableOfContentsDisplayStateModalHidden;
//                           break;
//                   }
//
//               } break;
//           }
//           [self updateToolbar];
//           [self updateTableOfContentsInsets];
    }
//    - (void)updateTableOfContentsDisplayModeWithTraitCollection:(UITraitCollection *)traitCollection {
//
//        BOOL isCompact = traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
//
//        if (isCompact) {
//            TableOfContentsDisplayStyle style = [self tableOfContentsStyleTweakValue];
//            switch (style) {
//                case TableOfContentsDisplayStyleOld:
//                    self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? TableOfContentsDisplaySideRight : TableOfContentsDisplaySideLeft;
//                    break;
//                case TableOfContentsDisplayStyleNext:
//                    self.tableOfContentsDisplaySide = TableOfContentsDisplaySideCenter;
//                    break;
//                case TableOfContentsDisplayStyleCurrent:
//                default:
//                    self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? TableOfContentsDisplaySideLeft : TableOfContentsDisplaySideRight;
//                    break;
//            }
//        } else {
//            self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? TableOfContentsDisplaySideLeft : TableOfContentsDisplaySideRight;
//        }
//
//        self.tableOfContentsDisplayMode = isCompact ? TableOfContentsDisplayModeModal : TableOfContentsDisplayModeInline;
//        switch (self.tableOfContentsDisplayMode) {
//            case TableOfContentsDisplayModeInline:
//                self.updateTableOfContentsSectionOnScrollEnabled = YES;
//                break;
//            case TableOfContentsDisplayModeModal:
//            default:
//                self.updateTableOfContentsSectionOnScrollEnabled = NO;
//                break;
//        }
//
//        self.tableOfContentsViewController.displayMode = self.tableOfContentsDisplayMode;
//        self.tableOfContentsViewController.displaySide = self.tableOfContentsDisplaySide;
//
//        [self updateTableOfContentsInsets];
//        [self setupTableOfContentsViewController];
//    }
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
        //dismiss(animated: true, completion: nil)
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
        return tableOfContentsDisplayMode == .modal
    }
}


extension ArticleViewController {

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
//        if let items = createTableOfContentsSections() {
//            let semanticContentAttribute:UISemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: article?.url.wmf_language)
//            self.tableOfContentsViewController = WMFTableOfContentsViewController(presentingViewController: tableOfContentsDisplayMode == .modal ? self : nil , items: items, delegate: self, semanticContentAttribute: semanticContentAttribute, theme: self.theme)
//        }
    }

    /**
     Append a read more section to the table of contents.
     */
    public func appendItemsToTableOfContentsIncludingAboutThisArticle(_ includeAbout: Bool, includeReadMore: Bool) {
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
    
    var backgroundView: UIVisualEffectView {
        let view = UIVisualEffectView(frame: CGRect.zero)
        view.autoresizingMask = .flexibleWidth
        view.effect = UIBlurEffect(style: self.theme.blurEffectStyle)
        view.alpha = 0.0
        return view
    }

    public func selectAndScrollToTableOfContentsItemForSection(_ section: MWKSection, animated: Bool) {
        tableOfContentsViewController?.selectAndScrollToItem(section, animated: animated)
    }
    
    public func selectAndScrollToTableOfContentsFooterItemAtIndex(_ index: Int, animated: Bool) {
        tableOfContentsViewController?.selectAndScrollToFooterItem(atIndex: index, animated: animated)
    }
}

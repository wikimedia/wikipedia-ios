
protocol ArticleContextMenuPresenting {
    // For Context Menus (used in iOS 13 and later)
    @available(iOS 13.0, *)
    func getPeekViewControllerAsync(for destination: Router.Destination, completion: @escaping (UIViewController?) -> Void)

    // Used for both Context Menus and Peek/Pop
    func hideFindInPage(_ completion: (() -> Void)?)
    var configuration: Configuration { get }

    //  For Peek/Pop (used by iOS 12 and earlier, can be removed when the oldest supported version is iOS 13)
    func getPeekViewController(for destination: Router.Destination) -> UIViewController?
}

enum ContextMenuCompletionType {
    case bail
    case timeout
    case success
}

// MARK:- Context Menu for Protocol (iOS 13 and later)
// All functions in this extension are for Context Menus (used in iOS 13 and later)
/// The ArticleContextMenuPresenting protocol extension has functions that are called by various classes'  WKUIDelegate functions, but the WKUIDelegate functions themselves
/// reside within the actual classes. This is because in testing, the degate methods were never called when they lived in the protocol extension - there would just be a silent failure.
/// Thus, there is some dupicated code in the actual classes for receiving the delegate calls, and those functions in turn call the shared code within this protocol extension.
/// More details: https://phabricator.wikimedia.org/T253891#6173598
@available(iOS 13.0, *)
extension ArticleContextMenuPresenting {
    func contextMenuConfigurationForElement(_ elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        let nullConfig = UIContextMenuConfiguration(identifier: nil, previewProvider: nil)

        let nullCompletion = {
            completionHandler(nullConfig)
        }

        guard let linkURL = elementInfo.linkURL else {
            nullCompletion()
            return
        }

        //moving into separate function for easier testability
        contextMenuConfigurationForLinkURL(linkURL) { (completionType, menuConfig) in
            guard completionType != .bail && completionType != .timeout else {
                nullCompletion()
                return
            }

            completionHandler(menuConfig)
        }
    }

    func contextMenuConfigurationForLinkURL(_ linkURL: URL, completionHandler: @escaping (ContextMenuCompletionType, UIContextMenuConfiguration?) -> Void) {

        // It's helpful if we can fetch the article before calling the completion
        // However, we need to timeout if it takes too long
        var didCallCompletion = false

        dispatchAfterDelayInSeconds(1.0, DispatchQueue.main) {
            if (!didCallCompletion) {
                completionHandler(.timeout, nil)
                didCallCompletion = true;
            }
        }

        getPeekViewControllerAsync(for: linkURL) { (peekParentVC) in
            assert(Thread.isMainThread)
            guard let peekParentVC = peekParentVC else {
                if (!didCallCompletion) {
                    completionHandler(.bail, nil)
                    didCallCompletion = true;
                }
                return
            }

            let peekVC = peekParentVC.wmf_PeekableChildViewController

            self.hideFindInPage(nil)
            let config = UIContextMenuConfiguration(identifier: linkURL as NSURL, previewProvider: { () -> UIViewController? in
                return peekParentVC
            }) { (suggestedActions) -> UIMenu? in
                return self.previewMenuElements(for: peekParentVC, suggestedActions: suggestedActions)
            }

            if let articlePeekVC = peekVC as? ArticlePeekPreviewViewController {
                articlePeekVC.fetchArticle {
                    assert(Thread.isMainThread)
                    if (!didCallCompletion) {
                        completionHandler(.success, config)
                        didCallCompletion = true
                    }
                }
            } else {
                if (!didCallCompletion) {
                    completionHandler(.success, config)
                    didCallCompletion = true
                }
            }
        }
    }

    func getPeekViewControllerAsync(for linkURL: URL, completion: @escaping (UIViewController?) -> Void) {
        let destination = configuration.router.destination(for: linkURL)
        getPeekViewControllerAsync(for: destination, completion: completion)
    }

    func previewMenuElements(for previewViewController: UIViewController, suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard let vc = previewViewController as? ArticleViewController else {
            return nil
        }
        let legacyActions = vc.previewActions
        let menuItems = legacyActions.map { (legacyAction) -> UIMenuElement in
            return UIAction(title: legacyAction.title) { (action) in
                legacyAction.handler(legacyAction, previewViewController)
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
    }
}

// MARK: Peek/Pop for Protocol (iOS 12 and earlier, on devices w/ 3D Touch)
// All functions in this extension are for 3D Touch menus. (Can be removed when the oldest supported version is iOS 13.)
extension ArticleContextMenuPresenting {
    func getPeekViewController(for linkURL: URL) -> UIViewController? {
        let destination = configuration.router.destination(for: linkURL)
        return getPeekViewController(for: destination)
    }

    func shouldPreview(linkURL: URL?) -> Bool {
        guard let linkURL = linkURL else {
            return false
        }
        return linkURL.isPreviewable
    }

    func previewingViewController(for linkURL: URL?) -> UIViewController?  {
        guard let linkURL = linkURL, let peekVC = getPeekViewController(for: linkURL) else {
            return nil
        }
        hideFindInPage(nil)
        return peekVC
    }
}

// MARK:- Context Menu for ArticleVC (iOS 13 and later)
// All functions in this extension are for Context Menus (used in iOS 13 and later)
extension ArticleViewController: ArticleContextMenuPresenting, WKUIDelegate {
    static let peekableImageExtensions: Set<String> = ["jpg", "jpeg", "gif", "png", "svg"]

    func getPeekViewControllerAsync(for destination: Router.Destination, completion: @escaping (UIViewController?) -> Void) {
        switch destination {
        case .inAppLink(let linkURL):
            // Request the media list to see if this is a link from the gallery
            getMediaList { (result) in
                switch result {
                case .success(let mediaList):
                    // Check the media list items to find the item for this link
                    let fileName = linkURL.lastPathComponent
                    if let item = mediaList.items.first(where: { (item) -> Bool in  return item.title == fileName }) {
                        let galleryVC = self.getGalleryViewController(for: item, in: mediaList)
                        galleryVC.setOverlayViewTopBarHidden(true)
                        completion(galleryVC)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    self.showError(error)
                    completion(nil)
                }
            }
        default:
            completion(getPeekViewController(for: destination))
        }
    }
    
    var previewActions: [UIPreviewAction] {
        let readActionTitle = WMFLocalizedString("button-read-now", value: "Read now", comment: "Read now button text used in various places.")
        let readAction = UIPreviewAction(title: readActionTitle, style: .default, handler: { (action, vc) in
            guard let vc = vc as? ArticleViewController else {
                return
            }
            vc.articlePreviewingDelegate?.readMoreArticlePreviewActionSelected(with: vc)
        })
        let saveActionTitle = article.isSaved ? WMFLocalizedString("button-saved-remove", value: "Remove from saved", comment: "Remove from saved button text used in various places.") : CommonStrings.saveTitle
        let saveAction = UIPreviewAction(title: saveActionTitle, style: .default) { (action, vc) in
            guard let vc = vc as? ArticleViewController else {
                return
            }
            let isSaved = vc.dataStore.savedPageList.toggleSavedPage(for: vc.articleURL)
            let notification = isSaved ? CommonStrings.accessibilitySavedNotification : CommonStrings.accessibilityUnsavedNotification
            UIAccessibility.post(notification: .announcement, argument: notification)
            vc.articlePreviewingDelegate?.saveArticlePreviewActionSelected(with: vc, didSave: isSaved, articleURL: vc.articleURL)
        }
        let logReadingListsSaveIfNeeded = { [weak self] in
            guard let delegate = self?.articlePreviewingDelegate as? EventLoggingEventValuesProviding else {
                return
            }
            self?.readingListsFunnel.logSave(category: delegate.eventLoggingCategory, label: delegate.eventLoggingLabel, articleURL: self?.articleURL)
        }
        let shareActionTitle = CommonStrings.shareMenuTitle
        let shareAction = UIPreviewAction(title: shareActionTitle, style: .default) { (action, vc) in
            guard let vc = vc as? ArticleViewController, let presenter = vc.articlePreviewingDelegate as? UIViewController else {
                return
            }
            let customActivity = vc.addToReadingListActivity(with: presenter, eventLogAction: logReadingListsSaveIfNeeded)
            guard let shareActivityViewController = vc.sharingActivityViewController(with: nil, button: vc.toolbarController.shareButton, shareFunnel: vc.shareFunnel, customActivity: customActivity) else {
                return
            }
            // Exclude the system Safari reading list activity to avoid confusion with our reading lists
            shareActivityViewController.excludedActivityTypes = [.addToReadingList]
            vc.articlePreviewingDelegate?.shareArticlePreviewActionSelected(with: vc, shareActivityController: shareActivityViewController)
        }
        
        var actions = [readAction, saveAction]
        
        if article.location != nil {
            let placeActionTitle = WMFLocalizedString("page-location", value: "View on a map", comment: "Label for button used to show an article on the map")
            let placeAction = UIPreviewAction(title: placeActionTitle, style: .default) { (action, vc) in
                guard let vc = vc as? ArticleViewController else {
                    return
                }
                vc.articlePreviewingDelegate?.viewOnMapArticlePreviewActionSelected(with: vc)
            }
            actions.append(placeAction)
        }
        
        actions.append(shareAction)
        
        return actions
    }

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        self.contextMenuConfigurationForElement(elementInfo, completionHandler: completionHandler)
    }

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: WKContextMenuElementInfo, willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating) {
        guard
            animator.preferredCommitStyle != .dismiss,
            let vc = animator.previewViewController
            else {
                return
        }

        animator.addCompletion {
            self.commitPreview(of: vc)
        }
    }

    // This function is used by both Peek/Pop and Context Menu (can remove this note when removing rest of Peek/Pop code, when oldest supported version is iOS 13)
    func getPeekViewController(for destination: Router.Destination) -> UIViewController? {
        switch destination {
        case .article(let articleURL):
            let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
            articleVC?.articlePreviewingDelegate = self
            articleVC?.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
            return articleVC
        default:
            return nil
        }
    }

    // This function is used by both Peek/Pop and Context Menu (can remove this note when removing rest of Peek/Pop code, when oldest supported version is iOS 13)
    func commitPreview(of viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? ArticleViewController {
            vc.wmf_removePeekableChildViewControllers()
            push(vc, animated: true)
        } else {
            if let vc = viewControllerToCommit as? WMFImageGalleryViewController {
                vc.setOverlayViewTopBarHidden(false)
            }
            presentEmbedded(viewControllerToCommit, style: .gallery)
        }
    }
}

// MARK: Peek/Pop for ArticleVC (iOS 12 and earlier, on devices w/ 3D Touch)
// All functions in this extension are for 3D Touch menus. (Can be removed when the oldest supported version is iOS 13.)
extension ArticleViewController {

    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return self.shouldPreview(linkURL: elementInfo.linkURL)
    }

    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        return self.previewingViewController(for: elementInfo.linkURL)
    }

    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        commitPreview(of: previewingViewController)
    }
}

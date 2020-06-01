extension ArticleViewController {
    static let peekableImageExtensions: Set<String> = ["jpg", "jpeg", "gif", "png", "svg"]
    
    func getPeekViewControllerAsync(for linkURL: URL, completion: @escaping (UIViewController?) -> Void) {
        let destination = configuration.router.destination(for: linkURL)
        getPeekViewControllerAsync(for: destination, completion: completion)
    }
    
    func getPeekViewController(for linkURL: URL) -> UIViewController? {
        let destination = configuration.router.destination(for: linkURL)
        return getPeekViewController(for: destination)
    }
    
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

extension ArticleViewController: WKUIDelegate {
    
    enum ContextMenuCompletionType {
        case bail
        case timeout
        case success
    }
    
    @available(iOS 13.0, *)

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
            
            self.hideFindInPage()
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
    
    // MARK: Context menus
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        
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
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: WKContextMenuElementInfo, willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating) {
        guard
            elementInfo.linkURL != nil,
            animator.preferredCommitStyle != .dismiss,
            let vc = animator.previewViewController
            else {
                return
        }
        
        animator.addCompletion {
            self.commitPreview(of: vc)
        }
    }
    
    // MARK: Peek/Pop (can be removed when the oldest supported version is iOS 13)
    
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        guard let linkURL = elementInfo.linkURL else {
            return false
        }
        return linkURL.isPreviewable
    }
    
    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        guard let linkURL = elementInfo.linkURL, let peekVC = getPeekViewController(for: linkURL) else {
            return nil
        }
        hideFindInPage()
        return peekVC
    }
    
    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        commitPreview(of: previewingViewController)
    }
    
}

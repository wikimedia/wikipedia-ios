import WMFComponents

// MARK: - Context Menu for ArticleVC (iOS 13 and later)
// All functions in this extension are for Context Menus (used in iOS 13 and later)
extension ArticleViewController: ArticleContextMenuPresenting, WKUIDelegate {
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

    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        self.contextMenuConfigurationForElement(elementInfo, completionHandler: completionHandler)
    }

    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: WKContextMenuElementInfo, willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating) {
        guard
            elementInfo.linkURL != nil,
            let vc = animator.previewViewController
            else {
                return
        }

        animator.preferredCommitStyle = .pop

        animator.addCompletion {
            self.commitPreview(of: vc)
        }
    }

    func getPeekViewController(for destination: Router.Destination) -> UIViewController? {
        switch destination {
        case .article(let newArticleURL):
            guard var currentArticleWithoutFragment = URLComponents(url: articleURL, resolvingAgainstBaseURL: false),
                  var newArticleWithoutFragment = URLComponents(url: newArticleURL, resolvingAgainstBaseURL: false) else {
                // Not a valid URL
              return nil
            }
            currentArticleWithoutFragment.fragment = nil
            newArticleWithoutFragment.fragment = nil

            let isDestinationReferenceForCurrentArticle = currentArticleWithoutFragment == newArticleWithoutFragment
            guard !isDestinationReferenceForCurrentArticle else {
              return nil
            }

            let peekVC = ArticlePeekPreviewViewController(articleURL: newArticleURL, article: nil, dataStore: dataStore, theme: theme, articlePreviewingDelegate: self)
            return peekVC
        default:
            return nil
        }
    }

    func commitPreview(of viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? ArticlePeekPreviewViewController {
            readMoreArticlePreviewActionSelected(with: vc)
        } else {
            if let vc = viewControllerToCommit as? WMFImageGalleryViewController {
                vc.setOverlayViewTopBarHidden(false)
                vc.modalTransitionStyle = .crossDissolve
                present(vc, animated: true)
                return
            }

            presentEmbedded(viewControllerToCommit)
        }
    }
}

// MARK: Peek/Pop for Lead Image of ArticleVC
extension ArticleViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // If gallery has not been opened on that article, self.mediaList is nil - and we need to create the media list
        guard let mediaList = self.mediaList ?? MediaList(from: leadImageView.wmf_imageURLToFetch) else {
            return nil
        }
        let previewProvider: UIContextMenuContentPreviewProvider = {

            let completion: ((Result<MediaList, Error>) -> Void) = { _ in
                // Nothing - We preload the medialist (if needed) to provide better performance in the likely case the user pops into image gallery.
            }
            self.getMediaList(completion)

            let galleryVC = self.getGalleryViewController(for: mediaList.items.first, in: mediaList)
            galleryVC.setOverlayViewTopBarHidden(true)
            return galleryVC
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider, actionProvider: nil)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            if self.mediaList != nil {
                self.showLeadImage()
            } else {
                // fetchAndDisplayGalleryViewController() is very similar to showLeadImage(). In both cases, if self.mediaList doesn't exist, we make
                // a network request to load it. When that mediaList network fetch is happening in showLeadImage, we don't do anything - so when
                // transitioning from peek to pop, we are back to the main article with no indication we are in the process of popping. This
                // only happens on very slow networks (especially since we try to preload the mediaList when peeking - see above), but when it happens
                // it is not great for the user. Solution: If a mediaList needs to be fetched, fetchAndDisplayGalleryViewController() fakes the loading
                // photo screen while loading that mediaList - providing a much smoother user experience.
                self.fetchAndDisplayGalleryViewController()
            }
        }
    }
}

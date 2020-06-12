import Foundation

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
/// The ArticleContextMenuPresenting protocol extension has functions that are called by various classes' WKUIDelegate functions, but the WKUIDelegate functions themselves
/// reside within the actual classes. This is because in testing, the delegate methods were never called when they lived in the protocol extension - there would just be a silent failure.
/// Thus, there is some duplicated code in the actual classes for receiving the delegate calls, and those functions in turn call the shared code within this protocol extension.
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
                didCallCompletion = true
            }
        }

        getPeekViewControllerAsync(for: linkURL) { (peekParentVC) in
            assert(Thread.isMainThread)
            guard let peekParentVC = peekParentVC else {
                if (!didCallCompletion) {
                    completionHandler(.bail, nil)
                    didCallCompletion = true
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

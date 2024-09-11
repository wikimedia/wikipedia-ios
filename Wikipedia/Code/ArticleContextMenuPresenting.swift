import Foundation
import UIKit

protocol ArticleContextMenuPresenting {
    func getPeekViewControllerAsync(for destination: Router.Destination, completion: @escaping (UIViewController?) -> Void)

    func hideFindInPage(_ completion: (() -> Void)?)
    var configuration: Configuration { get }
    var previewMenuItems: [UIMenuElement]? { get }
}

enum ContextMenuCompletionType {
    case bail
    case timeout
    case success
}

// MARK: - Context Menu for Protocol
// All functions in this extension are for Context Menus
/// The ArticleContextMenuPresenting protocol extension has functions that are called by various classes' WKUIDelegate functions, but the WKUIDelegate functions themselves
/// reside within the actual classes. This is because in testing, the delegate methods were never called when they lived in the protocol extension - there would just be a silent failure.
/// Thus, there is some duplicated code in the actual classes for receiving the delegate calls, and those functions in turn call the shared code within this protocol extension.
/// More details: https://phabricator.wikimedia.org/T253891#6173598
extension ArticleContextMenuPresenting {
    func contextMenuConfigurationForElement(_ elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        let nullCompletion = {
            completionHandler(nil)
        }

        // This "N/A" part is pretty hacky. But we don't want to do a preview for "view article in browser", and this is the URL that is sent
        // for "view article in browser". Without this "N/A" check, "View article in browser"'s preview and context menu shows the one for the
        // article "N/A", which seems more wrong. The trade off: previews for the actual article "N/A" don't work, either.
        guard let linkURL = elementInfo.linkURL, linkURL.wmf_title != "N/A" else {
            nullCompletion()
            return
        }

        // moving into separate function for easier testability
        contextMenuConfigurationForLinkURL(linkURL) { (completionType, menuConfig) in
            guard completionType != .bail && completionType != .timeout else {
                nullCompletion()
                return
            }

            completionHandler(menuConfig)
        }
    }

    func contextMenuConfigurationForLinkURL(_ linkURL: URL, ignoreTimeout: Bool = false, completionHandler: @escaping (ContextMenuCompletionType, UIContextMenuConfiguration?) -> Void) {

        // It's helpful if we can fetch the article before calling the completion
        // However, we need to timeout if it takes too long
        var didCallCompletion = false

        if !ignoreTimeout {
            dispatchAfterDelayInSeconds(1.0, DispatchQueue.main) {
                if !didCallCompletion {
                    completionHandler(.timeout, nil)
                    didCallCompletion = true
                }
            }
        }

        getPeekViewControllerAsync(for: linkURL) { (peekParentVC) in
            assert(Thread.isMainThread)
            guard let peekParentVC = peekParentVC else {
                if !didCallCompletion {
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
                return (peekParentVC as? ArticleContextMenuPresenting)?.previewMenu
            }

            if let articlePeekVC = peekVC as? ArticlePeekPreviewViewController {
                articlePeekVC.fetchArticle {
                    assert(Thread.isMainThread)
                    if !didCallCompletion {
                        completionHandler(.success, config)
                        didCallCompletion = true
                    }
                }
            } else {
                if !didCallCompletion {
                    completionHandler(.success, config)
                    didCallCompletion = true
                }
            }
        }
    }

    func getPeekViewControllerAsync(for linkURL: URL, completion: @escaping (UIViewController?) -> Void) {
        let permanentUsername = MWKDataStore.shared().authenticationManager.authStatePermanentUsername
        let destination = configuration.router.destination(for: linkURL, permanentUsername: permanentUsername)
        getPeekViewControllerAsync(for: destination, completion: completion)
    }

    var previewMenu: UIMenu? {
        guard let previewMenuItems = previewMenuItems else {
            return nil
        }

        return UIMenu(title: "", image: nil, identifier: nil, options: [], children: previewMenuItems)
    }
}

import UIKit

@objc(WMFViewControllerRouter)
class ViewControllerRouter: NSObject {
    @objc let router: Router
    unowned let appViewController: WMFAppViewController
    @objc(initWithAppViewController:router:)
    required init(appViewController: WMFAppViewController, router: Router) {
        self.appViewController = appViewController
        self.router = router
    }

    private func presentOrPush(_ viewController: UIViewController, with completion: @escaping () -> Void) -> Bool {
        guard let navigationController = appViewController.currentNavigationController else {
            completion()
            return false
        }

        if let presented = navigationController.presentedViewController {
            let wrapper = WMFThemeableNavigationController(rootViewController: viewController, theme:appViewController.theme, style: .gallery)
            presented.present(wrapper, animated: true, completion: completion)
        } else {
            navigationController.pushViewController(viewController, animated: true)
            completion()
        }
        
        return true
    }
    
    @objc(routeURL:completion:)
    public func route(_ url: URL, completion: @escaping () -> Void) -> Bool {
        let theme = appViewController.theme
        let destination = router.destination(for: url)
        switch destination {
        case .article(let articleURL):
            appViewController.swiftCompatibleShowArticle(with: articleURL, animated: true, completion: completion)
            return true
        case .externalLink(let linkURL):
            appViewController.navigate(to: linkURL, useSafari: true)
            completion()
            return true
        case .articleHistory(let linkURL, let articleTitle):
            let pageHistoryVC = PageHistoryViewController(pageTitle: articleTitle, pageURL: linkURL)
            return presentOrPush(pageHistoryVC, with: completion)
        case .articleDiffCompare(let linkURL, let fromRevID, let toRevID):
            guard let siteURL = linkURL.wmf_site,
              (fromRevID != nil || toRevID != nil) else {
                completion()
                return false
            }
            let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .compare, articleTitle: nil, hidesHistoryBackTitle: true)
            return presentOrPush(diffContainerVC, with: completion)
        case .articleDiffSingle(let linkURL, let fromRevID, let toRevID):
            guard let siteURL = linkURL.wmf_site,
                (fromRevID != nil || toRevID != nil) else {
                completion()
                return false
            }
            let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .single, articleTitle: nil, hidesHistoryBackTitle: true)
            return presentOrPush(diffContainerVC, with: completion)
        case .inAppLink(let linkURL):
            let singlePageVC = SinglePageWebViewController(url: linkURL, theme: theme)
            return presentOrPush(singlePageVC, with: completion)
        case .userTalk(let linkURL):
            guard let talkPageVC = TalkPageContainerViewController.userTalkPageContainer(url: linkURL, dataStore: appViewController.dataStore, theme: theme) else {
                completion()
                return false
            }
            return presentOrPush(talkPageVC, with: completion)
        default:
            completion()
            return false
        }
    }
    
}

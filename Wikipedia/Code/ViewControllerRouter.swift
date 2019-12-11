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
    
    
    @objc(routeURL:completion:)
    public func route(_ url: URL, completion: @escaping () -> Void) -> Bool {
        guard let navigationController = appViewController.currentNavigationController else {
            completion()
            return false
        }
        
        let theme = appViewController.theme
        
        let present = { (viewController: UIViewController) in
            defer {
                completion()
            }
            if let presented = navigationController.presentedViewController {
                let wrapper = WMFThemeableNavigationController(rootViewController: viewController, theme:theme, style: .gallery)
                presented.present(wrapper, animated: true)
            } else {
                navigationController.pushViewController(viewController, animated: true)
            }
        }

        do {
            let destination = try router.destination(for: url)
            switch destination {
            case .article(let articleURL):
                appViewController.showArticle(for: articleURL, animated: true, completion: completion)
                return true
            case .externalLink(let linkURL):
                appViewController.navigate(to: linkURL, useSafari: true)
                completion()
                return true
            case .articleHistory(let linkURL, let articleTitle):
                let pageHistoryVC = PageHistoryViewController(pageTitle: articleTitle, pageURL: linkURL)
                present(pageHistoryVC)
                return true
            case .articleDiffCompare(let linkURL, let fromRevID, let toRevID):
                guard let siteURL = linkURL.wmf_site,
                  (fromRevID != nil || toRevID != nil) else {
                    completion()
                    return false
                }
                let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .compare, articleTitle: nil, hidesHistoryBackTitle: true)
                present(diffContainerVC)
                return true
            case .articleDiffSingle(let linkURL, let fromRevID, let toRevID):
                guard let siteURL = linkURL.wmf_site,
                    (fromRevID != nil || toRevID != nil) else {
                    completion()
                    return false
                }
                let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .single, articleTitle: nil, hidesHistoryBackTitle: true)
                present(diffContainerVC)
                return true
            case .inAppLink(let linkURL):
                let singlePageVC = SinglePageWebViewController(url: linkURL, theme: theme)
                present(singlePageVC)
                return true
            case .userTalk(let linkURL):
                guard let talkPageVC = TalkPageContainerViewController.userTalkPageContainer(url: linkURL, dataStore: appViewController.dataStore, theme: theme) else {
                    completion()
                    return false
                }
                present(talkPageVC)
                return true
            default:
                completion()
                return false
            }
        } catch let error {
            DDLogError("Error routing link: \(error)")
        }
        completion()
        return false
    }
    
}

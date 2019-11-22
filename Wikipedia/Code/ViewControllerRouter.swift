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

        do {
            let destination = try router.destination(for: url)
            switch destination {
            case .article(let articleURL):
                appViewController.showArticle(for: articleURL, animated: true, completion: completion)
                return true
            case .externalLink(let linkURL):
                appViewController.wmf_openExternalUrl(linkURL)
                completion()
                return true
            case .articleHistory(let linkURL, let articleTitle):
                let pageHistoryVC = PageHistoryViewController(pageTitle: articleTitle, pageURL: linkURL)
                navigationController.pushViewController(pageHistoryVC, animated: true)
                completion()
                return true
            case .articleDiffCompare(let linkURL, let fromRevID, let toRevID):
                guard let siteURL = linkURL.wmf_site,
                  (fromRevID != nil || toRevID != nil) else {
                    completion()
                    return false
                }
                
                let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: appViewController.theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .compare, articleTitle: nil, hidesHistoryBackTitle: true)
                navigationController.pushViewController(diffContainerVC, animated: true)
                completion()
                return true
            case .articleDiffSingle(let linkURL, let fromRevID, let toRevID):
                guard let siteURL = linkURL.wmf_site,
                    (fromRevID != nil || toRevID != nil) else {
                    completion()
                    return false
                }
                
                let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: appViewController.theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .single, articleTitle: nil, hidesHistoryBackTitle: true)
                navigationController.pushViewController(diffContainerVC, animated: true)
                completion()
                return true
            case .inAppLink(let linkURL):
                let singlePageVC = SinglePageWebViewController(url: linkURL, theme: appViewController.theme)
                navigationController.pushViewController(singlePageVC, animated: true)
                completion()
                return true
            case .userTalk(let linkURL):
                guard let talkPageVC = TalkPageContainerViewController.userTalkPageContainer(url: linkURL, dataStore: appViewController.dataStore, theme: appViewController.theme) else {
                    completion()
                    return false
                }
                navigationController.pushViewController(talkPageVC, animated: true)
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



//case WMFUserActivityTypeUserTalk: {
//    NSURL *URL = activity.webpageURL;
//    if (!URL) {
//        done();
//        return NO;
//    }
//    WMFTalkPageContainerViewController *vc = [WMFTalkPageContainerViewController userTalkPageContainerWithURL:URL dataStore:self.dataStore theme:self.theme];
//    [self.currentNavigationController pushViewController:vc animated:YES];
//}

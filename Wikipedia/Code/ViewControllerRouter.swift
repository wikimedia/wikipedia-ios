import UIKit
import AVKit

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

        let showNewVC = {
            if viewController is AVPlayerViewController {
                navigationController.present(viewController, animated: true, completion: completion)
            } else {
                navigationController.pushViewController(viewController, animated: true)
                completion()
            }
        }

        /// For Article as a Living Doc modal - fix the nav bar in place
        if #available(iOS 13.0, *), navigationController.children.contains(where: { $0 is ArticleAsLivingDocViewController }) {
            if let vc = viewController as? SinglePageWebViewController, navigationController.modalPresentationStyle == .pageSheet {
                vc.doesUseSimpleNavigationBar = true
                vc.navigationBar.isBarHidingEnabled = false
            }
        }

        if let presentedVC = navigationController.presentedViewController {
            presentedVC.dismiss(animated: false, completion: showNewVC)
        } else {
            showNewVC()
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
            let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .compare, articleTitle: nil)
            return presentOrPush(diffContainerVC, with: completion)
        case .articleDiffSingle(let linkURL, let fromRevID, let toRevID):
            guard let siteURL = linkURL.wmf_site,
                (fromRevID != nil || toRevID != nil) else {
                completion()
                return false
            }
            let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, type: .single, articleTitle: nil)
            return presentOrPush(diffContainerVC, with: completion)
        case .inAppLink(let linkURL):
            let singlePageVC = SinglePageWebViewController(url: linkURL, theme: theme)
            return presentOrPush(singlePageVC, with: completion)
        case .audio(let audioURL):
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            let vc = AVPlayerViewController()
            let player = AVPlayer(url: audioURL)
            vc.player = player
            return presentOrPush(vc, with: completion)
        case .userTalk(let linkURL):
            guard let talkPageVC = TalkPageContainerViewController.userTalkPageContainer(url: linkURL, dataStore: appViewController.dataStore, theme: theme) else {
                completion()
                return false
            }
            return presentOrPush(talkPageVC, with: completion)
        case .onThisDay(let indexOfSelectedEvent):
            let dataStore = appViewController.dataStore
            guard let contentGroup = dataStore.viewContext.newestVisibleGroup(of: .onThisDay, forSiteURL: dataStore.primarySiteURL), let onThisDayVC = contentGroup.detailViewControllerWithDataStore(dataStore, theme: theme) as? OnThisDayViewController else {
                completion()
                return false
            }
            onThisDayVC.shouldShowNavigationBar = true
            if let index = indexOfSelectedEvent, let selectedEvent = onThisDayVC.events.first(where: { $0.index == NSNumber(value: index) }) {
                onThisDayVC.initialEvent = selectedEvent
            }
            return presentOrPush(onThisDayVC, with: completion)
        default:
            completion()
            return false
        }
    }
    
}

import UIKit
import AVKit

// Wrapper class for access in Objective-C
@objc class WMFRoutingUserInfoKeys: NSObject {
    @objc static var source: String {
        return RoutingUserInfoKeys.source
    }
}

// Wrapper class for access in Objective-C
@objc class WMFRoutingUserInfoSourceValue: NSObject {
    @objc static var deepLinkRawValue: String {
        return RoutingUserInfoSourceValue.deepLink.rawValue
    }
}

struct RoutingUserInfoKeys {
    static let talkPageReplyText = "talk-page-reply-text"
    static let source = "source"
}

enum RoutingUserInfoSourceValue: String {
    case talkPage
    case talkPageArchives
    case article
    case notificationsCenter
    case deepLink
    case account
    case search
    case inAppWebView
    case unknown
}

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
            } else if let createReadingListVC = viewController as? CreateReadingListViewController,
                       createReadingListVC.isInImportingMode {

                 let createReadingListNavVC = WMFThemeableNavigationController(rootViewController: createReadingListVC, theme: self.appViewController.theme)
                 navigationController.present(createReadingListNavVC, animated: true, completion: completion)
            } else {
                navigationController.pushViewController(viewController, animated: true)
                completion()
            }
        }

        // For Article as a Living Doc modal - fix the nav bar in place
        if navigationController.children.contains(where: { $0 is ArticleAsLivingDocViewController }) {
            if let vc = viewController as? SinglePageWebViewController, navigationController.modalPresentationStyle == .pageSheet {
                vc.doesUseSimpleNavigationBar = true
                vc.navigationBar.isBarHidingEnabled = false
            }
        }
        
        // pass along doesUseSimpleNavigationBar SinglePageWebViewController settings to the next one if needed
        if let lastWebVC = navigationController.children.last as? SinglePageWebViewController,
           let nextWebVC = viewController as? SinglePageWebViewController {
            nextWebVC.doesUseSimpleNavigationBar = lastWebVC.doesUseSimpleNavigationBar
        }

        if let presentedVC = navigationController.presentedViewController {
            presentedVC.dismiss(animated: false, completion: showNewVC)
        } else {
            showNewVC()
        }
        
        return true
    }
    
    @objc(routeURL:userInfo:completion:)
    public func route(_ url: URL, userInfo: [AnyHashable: Any]? = nil, completion: @escaping () -> Void) -> Bool {
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
        case .talk(let linkURL):
            let source = source(from: userInfo)
            guard let viewModel = TalkPageViewModel(pageType: .article, pageURL: linkURL, source: source, articleSummaryController: appViewController.dataStore.articleSummaryController, authenticationManager: appViewController.dataStore.authenticationManager, languageLinkController: appViewController.dataStore.languageLinkController) else {
                completion()
                return false
            }
            
            if let deepLinkData = talkPageDeepLinkData(linkURL: linkURL, userInfo: userInfo) {
                viewModel.deepLinkData = deepLinkData
            }
            
            let newTalkPage = TalkPageViewController(theme: theme, viewModel: viewModel)
            return presentOrPush(newTalkPage, with: completion)
        case .userTalk(let linkURL):
            if FeatureFlags.needsNewTalkPage {
                
                let source = source(from: userInfo)
                guard let viewModel = TalkPageViewModel(pageType: .user, pageURL: linkURL, source: source, articleSummaryController: appViewController.dataStore.articleSummaryController, authenticationManager: appViewController.dataStore.authenticationManager, languageLinkController: appViewController.dataStore.languageLinkController) else {
                    completion()
                    return false
                }
                
                if let deepLinkData = talkPageDeepLinkData(linkURL: linkURL, userInfo: userInfo) {
                    viewModel.deepLinkData = deepLinkData
                }
                
                let newTalkPage = TalkPageViewController(theme: theme, viewModel: viewModel)
                return presentOrPush(newTalkPage, with: completion)
            } else {
                guard let talkPageVC = TalkPageContainerViewController.userTalkPageContainer(url: linkURL, dataStore: appViewController.dataStore, theme: theme) else {
                    completion()
                    return false
                }
                return presentOrPush(talkPageVC, with: completion)
            }

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
            
        case .readingListsImport(let encodedPayload):
            guard appViewController.editingFlowViewControllerInHierarchy == nil else {
                // Do not show reading list import if user is in the middle of editing
                completion()
                return false
            }

            let createReadingListVC = CreateReadingListViewController(theme: theme, articles: [], encodedPageIds: encodedPayload, dataStore: appViewController.dataStore)
            createReadingListVC.delegate = appViewController
            return presentOrPush(createReadingListVC, with: completion)
        default:
            completion()
            return false
        }
    }
    
    private func talkPageDeepLinkData(linkURL: URL, userInfo: [AnyHashable: Any]?) -> TalkPageViewModel.DeepLinkData? {
        
        guard let topicTitle = linkURL.fragment else {
            return nil
        }
        
        let replyText = userInfo?[RoutingUserInfoKeys.talkPageReplyText] as? String
            
        let deepLinkData = TalkPageViewModel.DeepLinkData(topicTitle: topicTitle, replyText: replyText)
        return deepLinkData
    }
    
    private func source(from userInfo: [AnyHashable: Any]?) -> RoutingUserInfoSourceValue {
        guard let sourceString = userInfo?[RoutingUserInfoKeys.source] as? String,
              let source = RoutingUserInfoSourceValue(rawValue: sourceString) else {
            return .unknown
        }

        return source
    }
}

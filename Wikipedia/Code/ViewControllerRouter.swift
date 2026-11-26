import UIKit
import AVKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

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
    case watchlist
    case unknown
    case profile
}

@objc(WMFViewControllerRouter)
class ViewControllerRouter: NSObject {

    @objc let router: Router
    unowned let appViewController: WMFAppViewController
    private var createReadingListCoordinator: CreateReadingListCoordinator?
    private var watchlistFlowCoordinator: WatchlistFlowCoordinator?
    @objc(initWithAppViewController:router:)
    required init(appViewController: WMFAppViewController, router: Router) {
        self.appViewController = appViewController
        self.router = router
    }

    private func presentLoginViewController(with completion: @escaping () -> Void) -> Bool {

        appViewController.wmf_showLoginViewController(category: .unknown, theme: appViewController.theme)
        completion()
        return true
    }

    @MainActor
    private func presentReadingListImport(encodedPageIDs: String, with completion: @escaping () -> Void) -> Bool {
        guard let navigationController = appViewController.currentNavigationController else {
            completion()
            return false
        }

        let coordinator = CreateReadingListCoordinator(presentingViewController: navigationController, encodedPageIDs: encodedPageIDs, dataStore: appViewController.dataStore)
        coordinator.delegate = appViewController.savedCoordinator
        coordinator.didDismiss = { [weak self] in
            self?.createReadingListCoordinator = nil
        }
        createReadingListCoordinator = coordinator

        let showCoordinator = {
            coordinator.start()
            completion()
        }

        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.dismiss(animated: false, completion: showCoordinator)
        } else {
            showCoordinator()
        }

        return true
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

        let authManager = MWKDataStore.shared().authenticationManager
        let permanentUsername = authManager.authStatePermanentUsername

        let destination = router.destination(for: url, permanentUsername: permanentUsername)
        switch destination {
        case .article:
            assertionFailure("Use Article Coordinator instead")
            return false
        case .externalLink(let linkURL):
            appViewController.navigate(to: linkURL, useSafari: true)
            completion()
            return true
        case .articleHistory(let linkURL, let articleTitle):
            let pageHistoryVC = PageHistoryViewController(pageTitle: articleTitle, pageURL: linkURL, articleSummaryController: appViewController.dataStore.articleSummaryController, authenticationManager: appViewController.dataStore.authenticationManager)
            return presentOrPush(pageHistoryVC, with: completion)
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            guard let siteURL = linkURL.wmf_site,
                  fromRevID != nil || toRevID != nil else {
                completion()
                return false
            }

            let diffContainerVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: fromRevID, toRevisionID: toRevID, articleTitle: nil, articleSummaryController: appViewController.dataStore.articleSummaryController, authenticationManager: appViewController.dataStore.authenticationManager)
            return presentOrPush(diffContainerVC, with: completion)
        case .inAppLink(let linkURL):
            let config = SinglePageWebViewController.StandardConfig(url: linkURL, useSimpleNavigationBar: false)
            let singlePageVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            return presentOrPush(singlePageVC, with: completion)
        case .audio(let audioURL):
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            let vc = AVPlayerViewController()
            let player = AVPlayer(url: audioURL)
            vc.player = player
            return presentOrPush(vc, with: completion)
        case .talk(let linkURL):
            let source = source(from: userInfo)
            guard let viewModel = TalkPageViewModel(pageType: .article, pageURL: linkURL, source: source, articleSummaryController: appViewController.dataStore.articleSummaryController, authenticationManager: appViewController.dataStore.authenticationManager, languageLinkController: appViewController.dataStore.languageLinkController, dataStore: appViewController.dataStore) else {
                completion()
                return false
            }

            if let deepLinkData = talkPageDeepLinkData(linkURL: linkURL, userInfo: userInfo) {
                viewModel.deepLinkData = deepLinkData
            }

            let newTalkPage = TalkPageViewController(theme: theme, viewModel: viewModel)
            return presentOrPush(newTalkPage, with: completion)
        case .userTalk(let linkURL):
            let source = source(from: userInfo)
            guard let viewModel = TalkPageViewModel(pageType: .user, pageURL: linkURL, source: source, articleSummaryController: appViewController.dataStore.articleSummaryController, authenticationManager: appViewController.dataStore.authenticationManager, languageLinkController: appViewController.dataStore.languageLinkController, dataStore: appViewController.dataStore) else {
                completion()
                return false
            }

            if let deepLinkData = talkPageDeepLinkData(linkURL: linkURL, userInfo: userInfo) {
                viewModel.deepLinkData = deepLinkData
            }

            let newTalkPage = TalkPageViewController(theme: theme, viewModel: viewModel)
            return presentOrPush(newTalkPage, with: completion)

        case .onThisDay(let indexOfSelectedEvent):
            let dataStore = appViewController.dataStore
            guard let contentGroup = dataStore.viewContext.newestVisibleGroup(of: .onThisDay, forSiteURL: dataStore.primarySiteURL), let onThisDayVC = contentGroup.detailViewControllerWithDataStore(dataStore, theme: theme) as? OnThisDayViewController else {
                completion()
                return false
            }
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

            return MainActor.assumeIsolated {
                presentReadingListImport(encodedPageIDs: encodedPayload, with: completion)
            }
        case .login:
            return presentLoginViewController(with: completion)
        case .watchlist:
            return MainActor.assumeIsolated {
                showWatchlist(completion: completion)
            }
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

    @MainActor
    private func showWatchlist(completion: @escaping () -> Void) -> Bool {
        defer { completion() }
        guard let targetNavigationController = watchlistTargetNavigationController() else {
            return true
        }
        let coordinator = watchlistFlowCoordinator ?? WatchlistFlowCoordinator(dataStore: appViewController.dataStore, appViewController: appViewController)
        watchlistFlowCoordinator = coordinator
        coordinator.start(on: targetNavigationController)
        return true
    }

    private func watchlistTargetNavigationController() -> UINavigationController? {
        var targetNavigationController: UINavigationController? = appViewController.currentTabNavigationController
        if let presentedNavigationController = appViewController.presentedViewController as? UINavigationController,
           presentedNavigationController.viewControllers[0] is SettingsTabViewController {
            targetNavigationController = presentedNavigationController
        }
        return targetNavigationController
    }
}

import UIKit
import AVKit
import WMFComponents
import WMFData

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
    @objc(initWithAppViewController:router:)
    required init(appViewController: WMFAppViewController, router: Router) {
        self.appViewController = appViewController
        self.router = router
    }
    
    private func presentLoginViewController(with completion: @escaping () -> Void) -> Bool {
        
        appViewController.wmf_showLoginViewController(theme: appViewController.theme)
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
            } else if let createReadingListVC = viewController as? CreateReadingListViewController,
                      createReadingListVC.isInImportingMode {

                let createReadingListNavVC = WMFThemeableNavigationController(rootViewController: createReadingListVC, theme: self.appViewController.theme)
                navigationController.present(createReadingListNavVC, animated: true, completion: completion)
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
        case .article(let articleURL):
            appViewController.swiftCompatibleShowArticle(with: articleURL, animated: true, completion: completion)
            return true
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
        case .login:
            return presentLoginViewController(with: completion)
        case .watchlist:
            let userDefaults = UserDefaults.standard

            let targetNavigationController = watchlistTargetNavigationController()
            if !userDefaults.wmf_userHasOnboardedToWatchlists {
                showWatchlistOnboarding(targetNavigationController: targetNavigationController)
            } else {
                goToWatchlist(targetNavigationController: targetNavigationController)
            }

            return true
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
    
    private func watchlistTargetNavigationController() -> UINavigationController? {
        var targetNavigationController: UINavigationController? = appViewController.currentTabNavigationController
        if let presentedNavigationController = appViewController.presentedViewController as? UINavigationController,
           presentedNavigationController.viewControllers[0] is WMFSettingsViewController {
            targetNavigationController = presentedNavigationController
        }
        return targetNavigationController
    }
    
    private var watchlistFilterViewModel: WMFWatchlistFilterViewModel {
        
        let dataStore = appViewController.dataStore
        let appLanguages = dataStore.languageLinkController.preferredLanguages
        var localizedProjectNames = appLanguages.reduce(into: [WMFProject: String]()) { result, language in
            
            guard let wikimediaProject = WikimediaProject(siteURL: language.siteURL, languageLinkController: dataStore.languageLinkController),
                  let wmfProject = wikimediaProject.wmfProject else {
                return
            }
            
            result[wmfProject] = wikimediaProject.projectName(shouldReturnCodedFormat: false)
        }
        localizedProjectNames[.wikidata] = WikimediaProject.wikidata.projectName(shouldReturnCodedFormat: false)
        localizedProjectNames[.commons] = WikimediaProject.commons.projectName(shouldReturnCodedFormat: false)
        
        let localizedStrings = WMFWatchlistFilterViewModel.LocalizedStrings(
            title: CommonStrings.watchlistFilter,
            doneTitle: CommonStrings.doneTitle,
            localizedProjectNames: localizedProjectNames,
            wikimediaProjectsHeader: CommonStrings.wikimediaProjectsHeader,
            wikipediasHeader: CommonStrings.wikipediasHeader,
            commonAll: CommonStrings.filterOptionsAll,
            latestRevisionsHeader: CommonStrings.watchlistFilterLatestRevisionsHeader,
            latestRevisionsLatestRevision: CommonStrings.watchlistFilterLatestRevisionsOptionLatestRevision,
            latestRevisionsNotLatestRevision: CommonStrings.watchlistFilterLatestRevisionsOptionNotTheLatestRevision,
            watchlistActivityHeader: CommonStrings.watchlistFilterActivityHeader,
            watchlistActivityUnseenChanges: CommonStrings.watchlistFilterActivityOptionUnseenChanges,
            watchlistActivitySeenChanges: CommonStrings.watchlistFilterActivityOptionSeenChanges,
            automatedContributionsHeader: CommonStrings.watchlistFilterAutomatedContributionsHeader,
            automatedContributionsBot: CommonStrings.watchlistFilterAutomatedContributionsOptionBot,
            automatedContributionsHuman: CommonStrings.watchlistFilterAutomatedContributionsOptionHuman,
            significanceHeader: CommonStrings.watchlistFilterSignificanceHeader,
            significanceMinorEdits: CommonStrings.watchlistFilterSignificanceOptionMinorEdits,
            significanceNonMinorEdits: CommonStrings.watchlistFilterSignificanceOptionNonMinorEdits,
            userRegistrationHeader: CommonStrings.watchlistFilterUserRegistrationHeader,
            userRegistrationUnregistered: CommonStrings.watchlistFilterUserRegistrationOptionUnregistered,
            userRegistrationRegistered: CommonStrings.watchlistFilterUserRegistrationOptionRegistered,
            typeOfChangeHeader: CommonStrings.watchlistFilterTypeOfChangeHeader,
            typeOfChangePageEdits: CommonStrings.watchlistFilterTypeOfChangeOptionPageEdits,
            typeOfChangePageCreations: CommonStrings.watchlistFilterTypeOfChangeOptionPageCreations,
            typeOfChangeCategoryChanges: CommonStrings.watchlistFilterTypeOfChangeOptionCategoryChanges,
            typeOfChangeWikidataEdits: CommonStrings.watchlistFilterTypeOfChangeOptionWikidataEdits,
            typeOfChangeLoggedActions: CommonStrings.watchlistFilterTypeOfChangeOptionLoggedActions,
            addLanguage: CommonStrings.watchlistFilterAddLanguageButtonTitle
        )

        var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified
        let themeName = UserDefaults.standard.themeName
        if !Theme.isDefaultThemeName(themeName) {
            overrideUserInterfaceStyle = WMFAppEnvironment.current.theme.userInterfaceStyle
        }

        return WMFWatchlistFilterViewModel(localizedStrings: localizedStrings, overrideUserInterfaceStyle: overrideUserInterfaceStyle, loggingDelegate: appViewController)
    }
    
    func showWatchlistOnboarding(targetNavigationController: UINavigationController?) {
        let trackChanges = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "track-changes"), title: CommonStrings.watchlistTrackChangesTitle, subtitle: CommonStrings.watchlistTrackChangesSubtitle)
        let watchArticles = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "watch-articles"), title: CommonStrings.watchlistWatchChangesTitle, subtitle: CommonStrings.watchlistWatchChangesSubitle)
        let setExpiration = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "set-expiration"), title: CommonStrings.watchlistSetExpirationTitle, subtitle: CommonStrings.watchlistSetExpirationSubtitle)
        let viewUpdates = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "view-updates"), title: CommonStrings.watchlistViewUpdatesTitle, subtitle: CommonStrings.watchlistViewUpdatesSubitle)

        let viewModel = WMFOnboardingViewModel(title: CommonStrings.watchlistOnboardingTitle, cells: [trackChanges, watchArticles, setExpiration, viewUpdates], primaryButtonTitle: CommonStrings.continueButton, secondaryButtonTitle: CommonStrings.watchlistOnboardingLearnMore)

        let viewController = WMFOnboardingViewController(viewModel: viewModel)
        viewController.hostingController.delegate = self
        
        WatchlistFunnel.shared.logWatchlistOnboardingAppearance()

        targetNavigationController?.present(viewController, animated: true) {
            UserDefaults.standard.wmf_userHasOnboardedToWatchlists = true
        }
    }
    
    func goToWatchlist(targetNavigationController: UINavigationController?) {
        let localizedByteChange: (Int) -> String = { bytes in
            String.localizedStringWithFormat(
                WMFLocalizedString("watchlist-byte-change", value:"{{PLURAL:%1$d|%1$d byte|%1$d bytes}}", comment: "Amount of bytes changed for a revision displayed in watchlist - %1$@ is replaced with the number of bytes."),
                bytes
            )
        }

        let htmlStripped: (String) -> String = { inputString in
            let strippedString = inputString.removingHTML
            return strippedString
        }

        let attributedFilterString: (Int) -> AttributedString = { filters in
            let localizedString = String.localizedStringWithFormat(
                WMFLocalizedString("watchlist-number-filters", value:"Modify [{{PLURAL:%1$d|%1$d filter|%1$d filters}}](wikipedia://watchlist/filter) to see more Watchlist items", comment: "Amount of filters active in watchlist - %1$@ is replaced with the number of filters."),
                filters
            )
            
            let attributedString = (try? AttributedString(markdown: localizedString)) ?? AttributedString(localizedString)
            return attributedString
        }

        let localizedStrings = WMFWatchlistViewModel.LocalizedStrings(title: CommonStrings.watchlist, filter: CommonStrings.watchlistFilter, userButtonUserPage: CommonStrings.userButtonPage, userButtonTalkPage: CommonStrings.userButtonTalkPage, userButtonContributions: CommonStrings.userButtonContributions, userButtonThank: CommonStrings.userButtonThank, emptyEditSummary: CommonStrings.emptyEditSummary, userAccessibility: CommonStrings.userTitle, summaryAccessibility: CommonStrings.editSummaryTitle, userAccessibilityButtonDiff: CommonStrings.watchlistGoToDiff, localizedProjectNames: watchlistFilterViewModel.localizedStrings.localizedProjectNames, byteChange: localizedByteChange,  htmlStripped: htmlStripped)

        let presentationConfiguration = WMFWatchlistViewModel.PresentationConfiguration(showNavBarUponAppearance: true, hideNavBarUponDisappearance: true)

        let viewModel = WMFWatchlistViewModel(localizedStrings: localizedStrings, presentationConfiguration: presentationConfiguration)

        let localizedStringsEmptyView = WMFEmptyViewModel.LocalizedStrings(title: CommonStrings.watchlistEmptyViewTitle, subtitle: CommonStrings.watchlistEmptyViewSubtitle, titleFilter: CommonStrings.watchlistEmptyViewFilterTitle, buttonTitle: CommonStrings.watchlistEmptyViewButtonTitle, attributedFilterString: attributedFilterString)

        let reachabilityNotifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { (reachable, _) in
            if reachable {
                WMFAlertManager.sharedInstance.dismissAllAlerts()
            } else {
                WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noInternetConnection, sticky: true, dismissPreviousAlerts: true)
            }
        }

        let reachabilityHandler: WMFWatchlistViewController.ReachabilityHandler = { state in
            switch state {
            case .appearing:
                reachabilityNotifier.start()
            case .disappearing:
                reachabilityNotifier.stop()
            }
        }
        
        let emptyViewModel = WMFEmptyViewModel(localizedStrings: localizedStringsEmptyView, image: UIImage(named: "watchlist-empty-state"), imageColor: nil, numberOfFilters: viewModel.activeFilterCount)

        let watchlistViewController = WMFWatchlistViewController(viewModel: viewModel, filterViewModel: watchlistFilterViewModel, emptyViewModel: emptyViewModel, delegate: appViewController, loggingDelegate: appViewController, reachabilityHandler: reachabilityHandler)

        targetNavigationController?.pushViewController(watchlistViewController, animated: true)
    }
}

extension ViewControllerRouter: WMFOnboardingViewDelegate {
    
    func onboardingViewDidClickPrimaryButton() {
        
        let targetNavigationController = watchlistTargetNavigationController()
        
        WatchlistFunnel.shared.logWatchlistOnboardingTapContinue()
        
        if let presentedViewController = targetNavigationController?.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.goToWatchlist(targetNavigationController: targetNavigationController)
            }
        }
    }

    func onboardingViewDidClickSecondaryButton() {
        
        let targetNavigationController = watchlistTargetNavigationController()
        
        WatchlistFunnel.shared.logWatchlistOnboardingTapLearnMore()

        if let presentedViewController = targetNavigationController?.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ#Watchlist") else {
                    return
                }
                self?.appViewController.navigate(to: url)
            }
        }
    }
}

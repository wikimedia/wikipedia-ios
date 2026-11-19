import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Builds the Watchlist screen and answers its callbacks. `ViewControllerRouter` keeps one instance, because
/// the Watchlist screen holds its delegates weakly. `WatchlistCoordinator` only opens the deep link that leads here.
@MainActor
final class WatchlistFlowCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private weak var appViewController: WMFAppViewController?

    private var theme: Theme {
        appViewController?.theme ?? .standard
    }

    init(navigationController: UINavigationController, dataStore: MWKDataStore, appViewController: WMFAppViewController) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.appViewController = appViewController
        super.init()
    }

    @discardableResult
    func start() -> Bool {
        if UserDefaults.standard.wmf_userHasOnboardedToWatchlists {
            goToWatchlist()
        } else {
            showWatchlistOnboarding()
        }
        return true
    }

    private var localizedProjectNames: [WMFProject: String] {
        let languageLinkController = dataStore.languageLinkController
        var localizedProjectNames = languageLinkController.preferredLanguages.reduce(into: [WMFProject: String]()) { result, language in
            guard let wikimediaProject = WikimediaProject(siteURL: language.siteURL, languageLinkController: languageLinkController),
                  let wmfProject = wikimediaProject.wmfProject else {
                return
            }

            result[wmfProject] = wikimediaProject.projectName(shouldReturnCodedFormat: false)
        }
        localizedProjectNames[.wikidata] = WikimediaProject.wikidata.projectName(shouldReturnCodedFormat: false)
        localizedProjectNames[.commons] = WikimediaProject.commons.projectName(shouldReturnCodedFormat: false)
        return localizedProjectNames
    }

    private var watchlistFilterViewModel: WMFWatchlistFilterViewModel {
        let localizedStrings = WMFWatchlistFilterViewModel.LocalizedStrings(
            title: CommonStrings.watchlistFilter,
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

        return WMFWatchlistFilterViewModel(localizedStrings: localizedStrings, overrideUserInterfaceStyle: overrideUserInterfaceStyle, loggingDelegate: self)
    }

    private func showWatchlistOnboarding() {
        let trackChanges = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "track-changes"), title: CommonStrings.watchlistTrackChangesTitle, subtitle: CommonStrings.watchlistTrackChangesSubtitle)
        let watchArticles = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "watch-articles"), title: CommonStrings.watchlistWatchChangesTitle, subtitle: CommonStrings.watchlistWatchChangesSubitle)
        let setExpiration = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "set-expiration"), title: CommonStrings.watchlistSetExpirationTitle, subtitle: CommonStrings.watchlistSetExpirationSubtitle)
        let viewUpdates = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: UIImage(named: "view-updates"), title: CommonStrings.watchlistViewUpdatesTitle, subtitle: CommonStrings.watchlistViewUpdatesSubitle)

        let viewModel = WMFOnboardingViewModel(title: CommonStrings.watchlistOnboardingTitle, cells: [trackChanges, watchArticles, setExpiration, viewUpdates], primaryButtonTitle: CommonStrings.continueButton, secondaryButtonTitle: CommonStrings.watchlistOnboardingLearnMore)

        let viewController = WMFOnboardingViewController(viewModel: viewModel)
        viewController.hostingController.delegate = self

        WatchlistFunnel.shared.logWatchlistOnboardingAppearance()

        navigationController.present(viewController, animated: true) {
            UserDefaults.standard.wmf_userHasOnboardedToWatchlists = true
        }
    }

    private func goToWatchlist() {
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

        let viewModel = WMFWatchlistViewModel(localizedStrings: localizedStrings)

        let localizedStringsEmptyView = WMFEmptyViewModel.LocalizedStrings(title: CommonStrings.watchlistEmptyViewTitle, subtitle: CommonStrings.watchlistEmptyViewSubtitle, titleFilter: CommonStrings.watchlistEmptyViewFilterTitle, buttonTitle: CommonStrings.watchlistEmptyViewButtonTitle, attributedFilterString: attributedFilterString)

        let reachabilityNotifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { (reachable, _) in
            if reachable {
                Task { @MainActor in
                    WMFToastManager.sharedInstance.dismissCurrentToast()
                }
            } else {
                Task { @MainActor in
                    WMFToastManager.sharedInstance.showToast(CommonStrings.noInternetConnection, sticky: true, dismissPreviousToasts: true)
                }
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

        let watchlistViewController = WMFWatchlistViewController(viewModel: viewModel, filterViewModel: watchlistFilterViewModel, emptyViewModel: emptyViewModel, delegate: self, loggingDelegate: self, reachabilityHandler: reachabilityHandler)

        navigationController.pushViewController(watchlistViewController, animated: true)
    }
}

// MARK: - WMFOnboardingViewDelegate

extension WatchlistFlowCoordinator: WMFOnboardingViewDelegate {

    func onboardingViewDidClickPrimaryButton() {

        WatchlistFunnel.shared.logWatchlistOnboardingTapContinue()

        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.goToWatchlist()
            }
        }
    }

    func onboardingViewDidClickSecondaryButton() {

        WatchlistFunnel.shared.logWatchlistOnboardingTapLearnMore()

        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ#Watchlist") else {
                    return
                }
                self?.navigationController.navigate(to: url)
            }
        }
    }
}

// MARK: - WMFWatchlistDelegate

extension WatchlistFlowCoordinator: WMFWatchlistDelegate {

    public func watchlistUserDidTapDiff(project: WMFProject, title: String, revisionID: UInt, oldRevisionID: UInt) {
        let wikimediaProject = WikimediaProject(wmfProject: project)
        guard let siteURL = wikimediaProject.mediaWikiAPIURL(configuration: .current), !(revisionID == 0 && oldRevisionID == 0) else {
            return
        }

        let diffURL: URL?

        if revisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)")
        } else if oldRevisionID == 0 {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(revisionID)")
        } else {
            diffURL = siteURL.wmf_URL(withPath: "/wiki/Special:MobileDiff/\(oldRevisionID)...\(revisionID)")
        }

        let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.watchlist.rawValue]

        navigationController.navigate(to: diffURL, userInfo: userInfo)
    }

    public func watchlistUserDidTapUser(project: WMFProject, title: String, revisionID: UInt, oldRevisionID: UInt, username: String, action: WMFWatchlistUserButtonAction) {
        let wikimediaProject = WikimediaProject(wmfProject: project)
        guard let siteURL = wikimediaProject.mediaWikiAPIURL(configuration: .current) else {
            return
        }

        switch action {
        case .userPage:
            navigationController.navigate(to: siteURL.wmf_URL(withPath: "/wiki/User:\(username)"))
        case .userTalkPage:
            navigationController.navigate(to: siteURL.wmf_URL(withPath: "/wiki/User_talk:\(username)"))
        case .userContributions:
            navigationController.navigate(to: siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)"))
        case .thank(let revisionID):
            let performThanks = {
                let diffThanker = DiffThanker()
                diffThanker.thank(siteURL: siteURL, rev: Int(revisionID), completion: { result in
                    Task { @MainActor in
                        switch result {
                        case .success:
                            let successfulThanks = WMFLocalizedString("watchlist-thanks-success", value: "Your ‘Thanks’ was sent to %@", comment: "Message displayed in a toast on successful thanking of user in Watchlist view. %@ is replaced with the user being thanked.")
                            let successMessage = String.localizedStringWithFormat(successfulThanks, username)
                            WMFToastManager.sharedInstance.showRichToast(successMessage, subtitle: nil, image: UIImage(named: "watchlist-thanks-checkmark"), dismissPreviousToasts: true)
                        case .failure(let failure):
                            WMFToastManager.sharedInstance.showRichToast(failure.localizedDescription, subtitle: nil, image: nil, dismissPreviousToasts: true)
                        }
                    }
                })
            }

            if !UserDefaults.standard.wmf_didShowThankRevisionAuthorEducationPanel() {
                appViewController?.topMostViewController?.wmf_showThankRevisionAuthorEducationPanel(theme: theme, sendThanksHandler: {
                    WatchlistFunnel.shared.logThanksTapSend(project: wikimediaProject)
                    UserDefaults.standard.wmf_setDidShowThankRevisionAuthorEducationPanel(true)
                    performThanks()
                }, cancelHandler: {
                    WatchlistFunnel.shared.logThanksTapCancel(project: wikimediaProject)
                })
            } else {
                performThanks()
            }
        case .diff(let revId, let oldRevId):
            watchlistUserDidTapDiff(project: project, title: title, revisionID: revId, oldRevisionID: oldRevId)
        }
    }

    public func watchlistEmptyViewUserDidTapSearch() {
        NSUserActivity.wmf_navigate(to: NSUserActivity.wmf_searchView())
    }

    public func watchlistUserDidTapAddLanguage(from viewController: UIViewController, viewModel: WMFWatchlistFilterViewModel) {
        let languagesController = WMFLanguagesViewController(nibName: "WMFLanguagesViewController", bundle: nil)
        languagesController.title = CommonStrings.wikipediaLanguages
        languagesController.apply(theme)
        languagesController.delegate = self
        languagesController.showAllLanguages = true
        languagesController.showPreferredLanguages = false
        languagesController.showNonPreferredLanguages = false

        languagesController.userLanguageSelectionBlock = { [weak self, weak viewModel] in
            guard let self else { return }
            viewModel?.reloadWikipedias(localizedProjectNames: self.localizedProjectNames)
        }

        let navigationController = WMFComponentNavigationController(rootViewController: languagesController, modalPresentationStyle: .overFullScreen)
        viewController.present(navigationController, animated: true)
    }
}

// MARK: - WMFLanguagesViewControllerDelegate

extension WatchlistFlowCoordinator: WMFLanguagesViewControllerDelegate {

    public func languagesController(_ controller: WMFLanguagesViewController, didSelectLanguage language: MWKLanguageLink) {
        dataStore.languageLinkController.appendPreferredLanguage(language)
        controller.userLanguageSelectionBlock?()
        controller.dismiss(animated: true)
    }
}

// MARK: - WMFWatchlistLoggingDelegate

extension WatchlistFlowCoordinator: WMFWatchlistLoggingDelegate {
    public func logWatchlistDidLoad(itemCount: Int) {
        WatchlistFunnel.shared.logWatchlistLoaded(itemCount: itemCount)
    }

    public func logWatchlistUserDidTapNavBarFilterButton() {
        WatchlistFunnel.shared.logOpenFilterSettings()
    }

    public func logWatchlistUserDidSaveFilterSettings(filterSettings: WMFWatchlistFilterSettings, onProjects: [WMFProject]) {

        // Projects
        let commonsAndWikidataProjects: WatchlistFunnel.FilterEnabledList.Projects?

        if onProjects.contains(.commons) && onProjects.contains(.wikidata) {
            commonsAndWikidataProjects = .both
        } else if onProjects.contains(.commons) && onProjects.contains(.commons) {
            commonsAndWikidataProjects = .commons
        } else if onProjects.contains(.wikidata) {
            commonsAndWikidataProjects = .wikidata
        } else {
            commonsAndWikidataProjects = nil
        }

        // Wikis
        let wikipediaProjects = onProjects.map { WikimediaProject(wmfProject: $0) }.filter {
            switch $0 {
            case .wikipedia: return true
            default: return false
            }
        }

        let wikiIdentifiers = wikipediaProjects.map { $0.notificationsApiWikiIdentifier }

        // Latest
        let latest: WatchlistFunnel.FilterEnabledList.Latest
        switch filterSettings.latestRevisions {
        case .notTheLatestRevision:
            latest = .notLatest
        case .latestRevision:
            latest = .latest
        }

        // Activity
        let activity: WatchlistFunnel.FilterEnabledList.Activity
        switch filterSettings.activity {
        case .all:
            activity = .all
        case .seenChanges:
            activity = .seen
        case .unseenChanges:
            activity = .unseen
        }

        // Automated
        let automated: WatchlistFunnel.FilterEnabledList.Automated
        switch filterSettings.automatedContributions {
        case .all:
            automated = .all
        case .bot:
            automated = .bot
        case .human:
            automated = .nonBot
        }

        // Significance
        let significance: WatchlistFunnel.FilterEnabledList.Significance
        switch filterSettings.significance {
        case .all:
            significance = .all
        case .minorEdits:
            significance = .minor
        case .nonMinorEdits:
            significance = .nonMinor
        }

        // User Registration
        let userRegistration: WatchlistFunnel.FilterEnabledList.UserRegistration
        switch filterSettings.userRegistration {
        case .all:
            userRegistration = .all
        case .registered:
            userRegistration = .registered
        case .unregistered:
            userRegistration = .unregistered
        }

        // Type Change
        var onTypeChanges: [WatchlistFunnel.FilterEnabledList.TypeChange] = []
        for changeType in WMFWatchlistFilterSettings.ChangeType.allCases {
            if !filterSettings.offTypes.contains(changeType) {
                switch changeType {
                case .categoryChanges: onTypeChanges.append(.categoryChanges)
                case .loggedActions: onTypeChanges.append(.logActions)
                case .pageCreations: onTypeChanges.append(.pageCreations)
                case .pageEdits: onTypeChanges.append(.pageEdits)
                case .wikidataEdits: onTypeChanges.append(.wikidataEdits)
                }
            }
        }

        let filterEnabledList = WatchlistFunnel.FilterEnabledList(projects: commonsAndWikidataProjects, wikis: wikiIdentifiers, latest: latest, activity: activity, automated: automated, significance: significance, userRegistration: userRegistration, typeChange: onTypeChanges)

        WatchlistFunnel.shared.logSaveFilterSettings(filterEnabledList: filterEnabledList)
    }

    public func logWatchlistEmptyViewDidShow(type: WMFEmptyViewStateType) {
        switch type {
        case .noItems: WatchlistFunnel.shared.logWatchlistSawEmptyStateNoFilters()
        case .filter: WatchlistFunnel.shared.logWatchlistSawEmptyStateWithFilters()
        }
    }

    public func logWatchlistEmptyViewUserDidTapSearch() {
        WatchlistFunnel.shared.logWatchlistEmptyStateTapSearch()
    }

    public func logWatchlistEmptyViewUserDidTapModifyFilters() {
        WatchlistFunnel.shared.logWatchlistEmptyStateTapModifyFilters()
    }

    public func logWatchlistUserDidTapUserButton(project: WMFData.WMFProject) {

        let wikimediaProject = WikimediaProject(wmfProject: project)
        WatchlistFunnel.shared.logTapUserMenu(project: wikimediaProject)
    }

    public func logWatchlistUserDidTapUserButtonAction(project: WMFData.WMFProject, action: WMFComponents.WMFWatchlistUserButtonAction) {

        let wikimediaProject = WikimediaProject(wmfProject: project)

        switch action {
        case .userPage:
            WatchlistFunnel.shared.logTapUserPage(project: wikimediaProject)
        case .userTalkPage:
            WatchlistFunnel.shared.logTapUserTalk(project: wikimediaProject)
        case .userContributions:
            WatchlistFunnel.shared.logTapUserContributions(project: wikimediaProject)
        case .thank:
            WatchlistFunnel.shared.logTapUserThank(project: wikimediaProject)
        case .diff:
            break
        }
    }
}

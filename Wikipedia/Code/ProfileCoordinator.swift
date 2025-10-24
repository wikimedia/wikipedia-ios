import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData

@objc
enum ProfileCoordinatorSource: Int {
    case exploreOptOut
    case explore
    case article
    case places
    case saved
    case history
    case search
}

@objc(WMFProfileCoordinator)
final class ProfileCoordinator: NSObject, Coordinator, ProfileCoordinatorDelegate {
    
    // MARK: Coordinator Protocol Properties
    
    var navigationController: UINavigationController
    
    weak var delegate: LogoutCoordinatorDelegate?

    // MARK: Properties
    
    var theme: Theme
    let dataStore: MWKDataStore
    
    private weak var viewModel: WMFProfileViewModel?
    weak var badgeDelegate: YearInReviewBadgeDelegate?
    
    private let donateSouce: DonateCoordinator.Source
    private let targetRects = WMFProfileViewTargetRects()
    private var donateCoordinator: DonateCoordinator?
    private let yirCoordinator: YearInReviewCoordinator
    
    let sourcePage: ProfileCoordinatorSource
    
    
    // MARK: Lifecycle
    
    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, donateSouce: DonateCoordinator.Source, logoutDelegate: LogoutCoordinatorDelegate?, sourcePage: ProfileCoordinatorSource, yirCoordinator: YearInReviewCoordinator) {
        self.navigationController = navigationController
        self.theme = theme
        self.donateSouce = donateSouce
        self.dataStore = dataStore
        self.delegate = logoutDelegate
        self.sourcePage = sourcePage
        self.yirCoordinator = yirCoordinator
    }
    
    // MARK: Coordinator Protocol Methods
    
    @discardableResult
    @objc func start() -> Bool {
        let username = dataStore.authenticationManager.authStatePermanentUsername
        let tempAccountUsername = dataStore.authenticationManager.authStateTemporaryUsername
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        let isTemporaryAccount = dataStore.authenticationManager.authStateIsTemporary
        
        var finalPageTitle: String {
            if isLoggedIn {
                return username ?? CommonStrings.account
            } else if isTemporaryAccount {
                return CommonStrings.tempAccount
            } else {
                return CommonStrings.account
            }
        }
        let localizedStrings =
        WMFProfileViewModel.LocalizedStrings(
            pageTitle: finalPageTitle,
            doneButtonTitle: CommonStrings.doneTitle,
            notificationsTitle: CommonStrings.notificationsCenterTitle,
            userPageTitle: (isTemporaryAccount ? tempAccountUsername : CommonStrings.userButtonPage) ?? CommonStrings.userButtonPage,
            talkPageTitle: CommonStrings.talkPage,
            watchlistTitle: CommonStrings.watchlist,
            logOutTitle: CommonStrings.logoutTitle,
            donateTitle: CommonStrings.donateTitle,
            settingsTitle: CommonStrings.settingsTitle,
            joinWikipediaTitle: CommonStrings.joinLoginTitle,
            joinWikipediaSubtext: WMFLocalizedString("profile-page-join-subtext", value:"Sign up for a Wikipedia account to track your contributions, save articles offline, and sync across devices.", comment: "Information about signing in or up"),
            donateSubtext: WMFLocalizedString("profile-page-donate-subtext", value: "Or support Wikipedia with a donation to keep it free and accessible for everyone around the world.", comment: "Information about supporting Wikipedia through donations"),
            yearInReviewTitle: CommonStrings.yirTitle,
            yearInReviewLoggedOutSubtext:  WMFLocalizedString("profile-page-logged-out-year-in-review-subtext", value: "Log in or create an account to get an improved year in review next year", comment: "Footer text that appears underneath the Year in Review item in the Profile menu when the user is in a logged out state.")
        )
        
        let inboxCount = try? dataStore.remoteNotificationsController.numberOfUnreadNotifications()
        var yearInReviewDependencies: WMFProfileViewModel.YearInReviewDependencies? = nil
        if let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
           let primaryAppLanguageProject = WikimediaProject(siteURL: siteURL)?.wmfProject,
           let yearInReviewDataController = try? WMFYearInReviewDataController(),
           let countryCode = Locale.current.region?.identifier {
            yearInReviewDependencies = WMFProfileViewModel.YearInReviewDependencies(dataController: yearInReviewDataController, countryCode: countryCode, primaryAppLanguageProject: primaryAppLanguageProject)
        }

        let primaryWikiHasTempAccountsOn = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled

        let viewModel = WMFProfileViewModel(
            isLoggedIn: isLoggedIn,
            isTemporaryAccount: dataStore.authenticationManager.authStateIsTemporary && primaryWikiHasTempAccountsOn,
            localizedStrings: localizedStrings,
            inboxCount: Int(truncating: inboxCount ?? 0),
            coordinatorDelegate: self,
            yearInReviewDependencies: yearInReviewDependencies,
            badgeDelegate: badgeDelegate
        )
        
        let profileView = WMFProfileView(viewModel: viewModel)
        self.viewModel = viewModel
        let finalView = profileView.environmentObject(targetRects)
        let hostingController = WMFProfileHostingController(rootView: finalView, viewModel: viewModel)
        
        let profileNavVC = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .pageSheet)
        
        navigationController.present(profileNavVC, animated: true, completion: nil)
        
        return true
    }
    
    // MARK: - ProfileCoordinatorDelegate Methods
    
    public func handleProfileAction(_ action: ProfileAction) {
        switch action {
        case .showNotifications:
            dismissProfile {
                self.showNotifications()
            }
        case .showSettings:
            dismissProfile {
                self.showSettings()
            }
        case .showDonate:
            // Purposefully not dismissing profile here. We need DonateCoordinator to fetch and present an action sheet first before dismissing profile.
            self.showDonate()
        case .showUserPage:
            dismissProfile {
                self.showUserPage()
            }
        case .showUserTalkPage:
            dismissProfile {
                self.showUserTalkPage()
            }
        case .showWatchlist:
            dismissProfile {
                self.showWatchlist()
            }
        case .login:
            dismissProfile {
                self.login()
            }
        case .logout:
            dismissProfile {
                self.logout()
            }
        case .logDonateTap:
            self.logDonateTap()
        case .showYearInReview:
            dismissProfile {
                self.showYearInReview()
            }
        case .logYearInReviewTap:
            self.logYearInReviewTap()
        case .showUserPageTempAccount:
            dismissProfile {
                self.showUserPageTempAccount()
            }
        case .showUserTalkPageTempAccount:
            dismissProfile {
                self.showUserTalkPageTempAccount()
            }
        }
    }
    
    private func dismissProfile(completion: @escaping () -> Void) {
        navigationController.dismiss(animated: true) {
            completion()
        }
    }
    
    private func showNotifications() {
        let notificationsCoordinator = NotificationsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        notificationsCoordinator.start()
    }
    
    private func showSettings() {
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        settingsCoordinator.start()
    }
    
    private func showYearInReview() {
        yirCoordinator.start()
    }
    
    func showDonate() {
        
        guard let viewModel else {
            return
        }
        
        let getDonateButtonGlobalRect: () -> CGRect = { [weak self] in
            
            self?.targetRects.donateButtonFrame ?? .zero
        }
        
        let donateCoordinator = DonateCoordinator(navigationController: navigationController, source: donateSouce, dataStore: dataStore, theme: theme, navigationStyle: .dismissThenPush, setLoadingBlock: { isLoading in
            viewModel.isLoadingDonateConfigs = isLoading
        }, getDonateButtonGlobalRect: getDonateButtonGlobalRect)
        
        donateCoordinator.start()
        
        // Note: DonateCoordinator needs to handle a lot of delayed logic (fetch configs, present payment method action sheet, present native donate form and handle delegate callbacks from native donate form) as opposed to a fleeting navigation call with the other actions. For this reason we need to save it in a property so it isn't deallocated before this logic runs.
        self.donateCoordinator = donateCoordinator
    }
    
    
    private func showUserPage() {
        let username = dataStore.authenticationManager.authStatePermanentUsername
        if let username, let siteURL = dataStore.primarySiteURL {
            let userPageCoordinator = UserPageCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL)
            userPageCoordinator.start()
        }
    }
    
    private func showUserPageTempAccount() {
        let username = dataStore.authenticationManager.authStateTemporaryUsername
        if let siteURL = dataStore.primarySiteURL, let username {
            let userPageCoordinator = UserPageCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL)
            userPageCoordinator.start()
        }
    }
    
    private func showUserTalkPage() {
        let username = dataStore.authenticationManager.authStatePermanentUsername
        if let siteURL = dataStore.primarySiteURL, let username {
            let userTalkCoordinator = UserTalkCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL, dataStore: dataStore)
            userTalkCoordinator.start()
        }
    }
    
    private func showUserTalkPageTempAccount() {
        let username = dataStore.authenticationManager.authStateTemporaryUsername
        if let siteURL = dataStore.primarySiteURL, let username {
            let userTalkCoordinator = UserTalkCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL, dataStore: dataStore)
            userTalkCoordinator.start()
        }
    }
    
    private func showWatchlist() {
        let watchlistCoordinator = WatchlistCoordinator(navigationController: navigationController, dataStore: dataStore)
        watchlistCoordinator.start()
    }
    
    private func dismissProfile() {
        navigationController.dismiss(animated: true, completion: nil)
    }
    
    private func login() {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController, theme: theme)
        loginCoordinator.start()
    }
    
    private func logout() {
        let alertController = UIAlertController(title:CommonStrings.logoutAlertTitle, message: CommonStrings.logoutAlertMessage, preferredStyle: .alert)
        let logoutAction = UIAlertAction(title: CommonStrings.logoutTitle, style: .destructive) { [weak self] (action) in
            guard let self = self else {
                return
            }
            self.delegate?.didTapLogout()
        }
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func logDonateTap() {
        
        guard let metricsID = DonateCoordinator.metricsID(for: donateSouce, languageCode: dataStore.languageLinkController.appLanguage?.languageCode) else {
            return
        }
        
        switch sourcePage {
        case .exploreOptOut:
            DonateFunnel.shared.logOptOutExploreProfileDonate(metricsID: metricsID)
        case .explore:
            DonateFunnel.shared.logExploreProfileDonate(metricsID: metricsID)
        case .article:
            
            switch donateSouce {
            case .articleProfile(let articleURL):
                
                guard let siteURL = articleURL.wmf_site,
                      let project = WikimediaProject(siteURL: siteURL) else {
                    return
                }
                
                DonateFunnel.shared.logArticleProfileDonate(project: project, metricsID: metricsID)
            default:
                return
            }
        case .places:
            DonateFunnel.shared.logPlacesProfileDonate(metricsID: metricsID)
        case .saved:
            DonateFunnel.shared.logSavedProfileDonate(metricsID: metricsID)
        case .history:
            DonateFunnel.shared.logHistoryProfileDonate(metricsID: metricsID)
        case .search:
            DonateFunnel.shared.logSearchProfileDonate(metricsID: metricsID)
        }
    }
    
    func logYearInReviewTap() {
        DonateFunnel.shared.logProfileDidTapYearInReview()
    }
}


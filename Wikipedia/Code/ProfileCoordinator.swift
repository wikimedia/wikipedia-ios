import UIKit
import SwiftUI
import WMFComponents

@objc(WMFProfileCoordinator)
final class ProfileCoordinator: NSObject, Coordinator, ProfileCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    var navigationController: UINavigationController

    // MARK: Properties

    let theme: Theme
    let dataStore: MWKDataStore
    let username: String?

    // MARK: Lifecycle

    @objc init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.username = dataStore.authenticationManager.authStatePermanentUsername
    }

    // MARK: Coordinator Protocol Methods

    @objc func start() {
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent

        let pageTitle = WMFLocalizedString("profile-page-title-logged-out", value: "Account", comment: "Page title for non-logged in users")
        let localizedStrings =
            WMFProfileViewModel.LocalizedStrings(
                pageTitle: (isLoggedIn ? username : pageTitle) ?? pageTitle,
                doneButtonTitle: CommonStrings.doneTitle,
                notificationsTitle: WMFLocalizedString("profile-page-notification-title", value: "Notifications", comment: "Link to notifications page"),
                userPageTitle: WMFLocalizedString("profile-page-user-page-title", value: "User page", comment: "Link to user page"),
                talkPageTitle: WMFLocalizedString("profile-page-talk-page-title", value: "Talk page", comment: "Link to talk page"),
                watchlistTitle: WMFLocalizedString("profile-page-watchlist-title", value: "Watchlist", comment: "Link to watchlist"),
                logOutTitle: WMFLocalizedString("profile-page-logout", value: "Log out", comment: "Log out button"),
                donateTitle: WMFLocalizedString("profile-page-donate", value: "Donate", comment: "Link to donate"),
                settingsTitle: WMFLocalizedString("profile-page-settings", value: "Settings", comment: "Link to settings"),
                joinWikipediaTitle: WMFLocalizedString("profile-page-join-title", value: "Join Wikipedia / Log in", comment: "Link to sign up or sign in"),
                joinWikipediaSubtext: WMFLocalizedString("profile-page-join-subtext", value:"Sign up for a Wikipedia account to track your contributions, save articles offline, and sync across devices.", comment: "Information about signing in or up"),
                donateSubtext: WMFLocalizedString("profile-page-donate-subtext", value: "Or support Wikipedia with a donation to keep it free and accessible for everyone around the world.", comment: "Information about supporting Wikipedia through donations")
            )

        let inboxCount = try? dataStore.remoteNotificationsController.numberOfUnreadNotifications()

        let viewModel = WMFProfileViewModel(
            isLoggedIn: isLoggedIn,
            localizedStrings: localizedStrings,
            inboxCount: Int(truncating: inboxCount ?? 0),
            coordinatorDelegate: self
        )

        var profileView = WMFProfileView(viewModel: viewModel)
        profileView.donePressed = { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        }
        let hostingController = UIHostingController(rootView: profileView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = true
        }

        navigationController.present(hostingController, animated: true, completion: nil)
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
            dismissProfile {
                self.showDonate()
            }
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
        }
    }

    private func dismissProfile(completion: @escaping () -> Void) {
        navigationController.dismiss(animated: true) {
            completion()
        }
    }

    func showNotifications() {
        let notificationsCoordinator = NotificationsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        notificationsCoordinator.start()
    }

    func showSettings() {
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        settingsCoordinator.start()
    }

    func showDonate() {
        // TODO
    }

    func showUserPage() {
        if let username, let siteURL = dataStore.primarySiteURL {
            let userPageCoordinator = UserPageCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL)
            userPageCoordinator.start()
        }
    }

    func showUserTalkPage() {
        if let siteURL = dataStore.primarySiteURL, let username {
            let userTalkCoordinator = UserTalkCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL, dataStore: dataStore)
            userTalkCoordinator.start()
        }
    }

    func showWatchlist() {
        let watchlistCoordinator = WatchlistCoordinator(navigationController: navigationController, dataStore: dataStore)
        watchlistCoordinator.start()
    }

    private func dismissProfile() {
        navigationController.dismiss(animated: true, completion: nil)
    }

}


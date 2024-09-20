import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFProfileCoordinator)
class ProfileCoordinator: NSObject, Coordinator, ProfileCoordinatorDelegate {

    // MARK: Coordinator Protocol Properties

    var navigationController: UINavigationController

    // MARK: Properties

    let theme: Theme
    let dataStore: MWKDataStore
    private let donateSouce: DonateCoordinator.Source
    private let targetRects = WMFProfileViewTargetRects()
    private weak var viewModel: WMFProfileViewModel?
    
    private var donateCoordinator: DonateCoordinator?

    // MARK: Lifecycle
    
    @objc static func profileCoordinatorForSettingsProfileButton(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) -> ProfileCoordinator {
        return ProfileCoordinator(navigationController: navigationController, theme: theme, donateSouce: .settingsProfile, dataStore: dataStore)
    }

    init(navigationController: UINavigationController, theme: Theme, donateSouce: DonateCoordinator.Source, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.donateSouce = donateSouce
        self.dataStore = dataStore
    }

    // MARK: Coordinator Protocol Methods

    @objc func start() {
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent

        let pageTitle = WMFLocalizedString("profile-page-title-logged-out", value: "Account", comment: "Page title for non-logged in users")
        let localizedStrings =
            WMFProfileViewModel.LocalizedStrings(
                pageTitle: (isLoggedIn ? MWKDataStore.shared().authenticationManager.authStatePermanentUsername : pageTitle) ?? pageTitle,
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
        self.viewModel = viewModel
        let finalView = profileView.environmentObject(targetRects)
        let hostingController = UIHostingController(rootView: finalView)
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
            // Purposefully not dismissing profile here. We need DonateCoordinator to fetch and present an action sheet first before dismissing profile.
            self.showDonate()
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
        
        guard let viewModel else {
            return
        }
        
        let donateCoordinator = DonateCoordinator(navigationController: navigationController, donateButtonGlobalRect: targetRects.donateButtonFrame, source: donateSouce, dataStore: dataStore, theme: theme, setLoadingBlock: { isLoading in
            viewModel.isLoadingDonateConfigs = isLoading
        })
        
        donateCoordinator.start()
        
        // Note: DonateCoordinator needs to handle a lot of delayed logic (fetch configs, present payment method action sheet, present native donate form and handle delegate callbacks from native donate form) as opposed to a fleeting navigation call with the other actions. For this reason we need to save it in a property so it isn't deallocated before this logic runs.
        self.donateCoordinator = donateCoordinator
    }
    

    private func dismissProfile() {
        navigationController.dismiss(animated: true, completion: nil)
    }

}


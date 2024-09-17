import UIKit
import SwiftUI
import WMFComponents

class ProfileCoordinator: Coordinator, ProfileCoordinatorDelegate {

    var navigationController: UINavigationController

    let theme: Theme
    let dataStore: MWKDataStore

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }

    func start() {
        let viewModel = ProfileViewModel(isLoggedIn: true, coordinatorDelegate: self)
        viewModel.onDismiss = { [weak self] in
            self?.dismissProfile()
        }
        let profileView = WMFProfileView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: profileView)
        hostingController.title = "Account"
        navigationController.present(hostingController, animated: true)
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
        // call another coordinator
    }

    func showDonate() {
        // call another coordinator
    }

    private func dismissProfile() {
        navigationController.dismiss(animated: true, completion: nil)
    }

}


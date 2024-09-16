import UIKit
import SwiftUI
import WMFComponents

class ProfileCoordinator: Coordinator, ProfileCoordinatorDelegate, NotificationsCoordinatorDelegate {
    
    var childCoordinators: [Coordinator] = []
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
        let profileView = WMFProfileView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: profileView)
        hostingController.title = "Account"
        navigationController.pushViewController(hostingController, animated: true)
    }

    // MARK: - ProfileCoordinatorDelegate Methods

    func showNotifications() {
        let notificationsCoordinator = NotificationsCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        notificationsCoordinator.delegate = self
        childCoordinators.append(notificationsCoordinator)
        notificationsCoordinator.start()
    }

    public func notificationsCoordinatorDidFinish(_ coordinator: NotificationsCoordinator) {
//            childCoordinators = childCoordinators.filter { $0 !== coordinator }
        }
}


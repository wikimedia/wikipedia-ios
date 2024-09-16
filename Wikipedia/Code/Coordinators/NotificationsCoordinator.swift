import UIKit

public protocol NotificationsCoordinatorDelegate: AnyObject {
    func notificationsCoordinatorDidFinish(_ coordinator: NotificationsCoordinator)
}

public class NotificationsCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    public weak var delegate: NotificationsCoordinatorDelegate?

    let theme: Theme
    let dataStore: MWKDataStore

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }

    func start() {
        let viewModel = NotificationsCenterViewModel(notificationsController: dataStore.notificationsController, remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: self.dataStore.languageLinkController)

        let notificationsVC = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        notificationsVC.coordinator = self
        navigationController.pushViewController(notificationsVC, animated: true)
    }

    @objc private func doneTapped() {
        didFinish()
    }

    public func didFinish() {
        delegate?.notificationsCoordinatorDidFinish(self)
    }

    // Add navigation methods for other flows from Notifications? Or keep it uikit for now?

}

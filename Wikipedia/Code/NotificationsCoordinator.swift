import UIKit

public final class NotificationsCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties

    var navigationController: UINavigationController

    // MARK: Properties
    
    let theme: Theme
    let dataStore: MWKDataStore

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }

    // MARK: Coordinator Protocol Methods

    func start() {
        let viewModel = NotificationsCenterViewModel(notificationsController: dataStore.notificationsController, remoteNotificationsController: dataStore.remoteNotificationsController, languageLinkController: self.dataStore.languageLinkController)
        let notificationsVC = NotificationsCenterViewController(theme: theme, viewModel: viewModel)
        navigationController.pushViewController(notificationsVC, animated: true)
    }

}

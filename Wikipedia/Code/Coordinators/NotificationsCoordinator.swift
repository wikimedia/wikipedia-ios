import UIKit

public class NotificationsCoordinator: Coordinator {
    
    var navigationController: UINavigationController

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
        navigationController.pushViewController(notificationsVC, animated: true)
    }

}

import UIKit

final class WatchlistCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties
    
    var navigationController: UINavigationController

    // MARK: Properties

    let dataStore: MWKDataStore

    // MARK: Lifecycle

    init(navigationController: UINavigationController, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.dataStore = dataStore
    }

    func start() {
        guard let linkURL = dataStore.primarySiteURL?.wmf_URL(withTitle: "Special:Watchlist"),
        let userActivity = NSUserActivity.wmf_activity(for: linkURL) else {
            return
        }

        NSUserActivity.wmf_navigate(to: userActivity)
    }
}

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

    @discardableResult
    func start() -> Bool {
        guard let linkURL = dataStore.primarySiteURL?.wmf_URL(withTitle: "Special:Watchlist"),
              let userActivity = NSUserActivity.wmf_activity(for: linkURL) else {
            return false
        }

        NSUserActivity.wmf_navigate(to: userActivity)
        return true
    }
}

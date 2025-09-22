import UIKit

final class UserPageCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties
    
    var navigationController: UINavigationController

    // MARK: Properties

    private var theme: Theme
    private var username: String
    private var siteURL: URL

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, username: String, siteURL: URL) {
        self.navigationController = navigationController
        self.theme = theme
        self.username = username
        self.siteURL = siteURL
    }

    @discardableResult
    func start() -> Bool {
        guard let url = siteURL.wmf_URL(withPath: "/wiki/User:\(username)") else {
            return false
        }
        
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: false)
        let singlePageWebViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        navigationController.pushViewController(singlePageWebViewController, animated: true)
        return true
    }
}

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

    func start() {
        if let url = siteURL.wmf_URL(withPath: "/wiki/User:\(username)", isMobile: true) {
            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: false)
            let singlePageWebViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
            navigationController.pushViewController(singlePageWebViewController, animated: true)
        }
    }
}

import UIKit

final class UserPageCoordinator: Coordinator {
    var navigationController: UINavigationController

    private var theme: Theme
    private var username: String
    private var siteURL: URL

    init(navigationController: UINavigationController, theme: Theme, username: String, siteURL: URL) {
        self.navigationController = navigationController
        self.theme = theme
        self.username = username
        self.siteURL = siteURL
    }

    func start() {
        if let url = siteURL.wmf_URL(withPath: "/wiki/User:\(username)", isMobile: true) {
            let singlePageWebViewController = SinglePageWebViewController(url: url, theme: theme)
            let navVC = WMFThemeableNavigationController(rootViewController: singlePageWebViewController, theme: theme)
            navigationController.present(navVC, animated: true)
        }
    }
}

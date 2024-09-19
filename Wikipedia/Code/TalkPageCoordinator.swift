import UIKit

final class UserTalkCoordinator: Coordinator {
    var navigationController: UINavigationController

    private var theme: Theme
    private var username: String
    private var siteURL: URL?
    private var dataStore: MWKDataStore

    init(navigationController: UINavigationController, theme: Theme, username: String, siteURL: URL, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.username = username
        self.dataStore = dataStore
        self.siteURL = dataStore.primarySiteURL
    }

    func start() {
        guard let siteURL else {
            return
        }
        guard let viewModel = TalkPageViewModel(pageType: .user, pageTitle: username, siteURL: siteURL, source: .profile, articleSummaryController: dataStore.articleSummaryController, authenticationManager: dataStore.authenticationManager, languageLinkController: dataStore.languageLinkController) else {
            return
        }

        let talkPageViewController = TalkPageViewController(theme: theme, viewModel: viewModel)
        let navVC = WMFThemeableNavigationController(rootViewController: talkPageViewController, theme: theme)
        navigationController.present(navVC, animated: true) //fix back button missing
    }

}

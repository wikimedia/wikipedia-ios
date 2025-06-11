import UIKit

final class UserTalkCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties
    
    var navigationController: UINavigationController
    
    // MARK: Properties

    private var theme: Theme
    private var username: String
    private var siteURL: URL?
    private var dataStore: MWKDataStore

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, username: String, siteURL: URL, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.username = username
        self.dataStore = dataStore
        self.siteURL = dataStore.primarySiteURL
    }

    @discardableResult
    func start() -> Bool {
        guard let siteURL else {
            return false
        }
        
        let title = TalkPageType.user.titleWithCanonicalNamespacePrefix(title: username, siteURL: siteURL)
        
        guard let viewModel = TalkPageViewModel(pageType: .user, pageTitle: title, siteURL: siteURL, source: .profile, articleSummaryController: dataStore.articleSummaryController, authenticationManager: dataStore.authenticationManager, languageLinkController: dataStore.languageLinkController, dataStore: dataStore) else {
            return false
        }

        let talkPageViewController = TalkPageViewController(theme: theme, viewModel: viewModel)
        navigationController.pushViewController(talkPageViewController, animated: true)
        return true
    }

}

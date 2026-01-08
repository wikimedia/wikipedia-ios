import WMF
import WMFData

@MainActor
final class RandomArticleCoordinator: Coordinator, ArticleTabCoordinating {
    let navigationController: UINavigationController
    private(set) var articleURL: URL?
    private(set) var siteURL: URL?
    private let dataStore: MWKDataStore
    var theme: Theme
    private let source: ArticleSource
    private let animated: Bool
    private let replaceLastViewControllerInNavStack: Bool

    // Article Tabs Properties
    let tabConfig: ArticleTabConfig
    var tabIdentifier: UUID?
    var tabItemIdentifier: UUID?

    init(navigationController: UINavigationController, articleURL: URL?, siteURL: URL?, dataStore: MWKDataStore, theme: Theme, source: ArticleSource, animated: Bool, tabConfig: ArticleTabConfig = .appendArticleAndAssignCurrentTab, replaceLastViewControllerInNavStack: Bool = false) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.siteURL = siteURL
        self.dataStore = dataStore
        self.theme = theme
        self.source = source
        self.animated = animated
        self.replaceLastViewControllerInNavStack = replaceLastViewControllerInNavStack
        self.tabConfig = tabConfig
    }
    
    @MainActor @discardableResult
    func start() -> Bool {
        
        // We want to push on a particular random article.
        if var articleURL {
            // assign language variant code if needed (taken from AppVC's processUserActivity method)
            if articleURL.wmf_languageVariantCode == nil {
                articleURL.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(articleURL.wmf_languageCode)
            }
            
            guard let vc = RandomArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source) else {
                return false
            }
            
            prepareToShowTabsOverview(articleViewController: vc, dataStore)
            
            Task {
                await trackArticleTab(articleViewController: vc)
                
                Task { @MainActor in
                    if replaceLastViewControllerInNavStack {
                        var viewControllers = navigationController.viewControllers
                        viewControllers[viewControllers.count - 1] = vc
                        navigationController.setViewControllers(viewControllers, animated: animated)
                    } else {
                        navigationController.pushViewController(vc, animated: animated)
                    }
                }
            }
            
        // Push on FirstRandomViewController (which fetches a random article on load) instead
        } else if var siteURL {
            
            // assign language variant code if needed (taken from AppVC's processUserActivity method)
            if siteURL.wmf_languageVariantCode == nil {
                siteURL.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(siteURL.wmf_languageCode)
            }
            
            let vc = FirstRandomViewController(siteURL: siteURL, dataStore: dataStore, theme: theme)
            navigationController.pushViewController(vc, animated: animated)
            
        }
        return true
    }
}

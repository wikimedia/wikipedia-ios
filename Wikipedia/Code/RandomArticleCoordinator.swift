import WMF

final class RandomArticleCoordinator: Coordinator {
    let navigationController: UINavigationController
    private(set) var articleURL: URL?
    private(set) var siteURL: URL?
    private let dataStore: MWKDataStore
    var theme: Theme
    private let source: ArticleSource
    
    init(navigationController: UINavigationController, articleURL: URL?, siteURL: URL?, dataStore: MWKDataStore, theme: Theme, source: ArticleSource) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.siteURL = siteURL
        self.dataStore = dataStore
        self.theme = theme
        self.source = source
    }
    
    @discardableResult
    func start() -> Bool {
        
        // We want to push on a particular random article
        if var articleURL {
            // assign language variant code if needed (taken from AppVC's processUserActivity method)
            if articleURL.wmf_languageVariantCode == nil {
                articleURL.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(articleURL.wmf_languageCode)
            }
            
            guard let vc = RandomArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source) else {
                return false
            }
            navigationController.pushViewController(vc, animated: true)
            
        // Push on any old random article
        } else if var siteURL {
            
            // assign language variant code if needed (taken from AppVC's processUserActivity method)
            if siteURL.wmf_languageVariantCode == nil {
                siteURL.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(siteURL.wmf_languageCode)
            }
            
            let vc = WMFFirstRandomViewController(siteURL: siteURL, dataStore: dataStore, theme: theme)
            navigationController.pushViewController(vc, animated: true)
            
        }
        return true
    }
}

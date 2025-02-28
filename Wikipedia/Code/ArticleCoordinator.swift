import WMF
import WMFData

@objc(WMFArticleCoordinator)
final class ArticleCoordinator: NSObject, Coordinator {
    let navigationController: UINavigationController
    private(set) var articleURL: URL
    private let dataStore: MWKDataStore
    var theme: Theme
    private let source: ArticleSource
    private let isRestoringState: Bool
    private let needsAnimation: Bool
    private(set) var tab: WMFData.Tab?
    private(set) var article: WMFData.Tab.Article?
    
    private var project: WikimediaProject? {
        guard let siteURL = articleURL.wmf_site,
              let project = WikimediaProject(siteURL: siteURL) else {
            return nil
        }
        return project
    }
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, source: ArticleSource, isRestoringState: Bool = false, needsAnimation: Bool = true, tab: WMFData.Tab? = nil, article: WMFData.Tab.Article? = nil) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        self.source = source
        self.isRestoringState = isRestoringState
        self.needsAnimation = needsAnimation
        self.tab = tab
        self.article = article
    }
    
    @discardableResult
    func start() -> Bool {
        
        // assign language variant code if needed (taken from AppVC's processUserActivity method)
        if articleURL.wmf_languageVariantCode == nil {
            articleURL.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(articleURL.wmf_languageCode)
        }
        
        guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source, articleCoordinator: self) else {
            return false
        }
        articleVC.isRestoringState = isRestoringState
        navigationController.pushViewController(articleVC, animated: needsAnimation)
        
        // If instantiated with a tab, article is already associated with tab. No need to add again.
        if tab == nil && article == nil {
            addArticleToCurrentTab()
        }
        return true
    }
    
    private func addArticleToCurrentTab() {
        guard let title = articleURL.wmf_title,
              let project = project?.wmfProject else {
            return
        }
        
        let article: WMFData.Tab.Article = WMFData.Tab.Article(title: title, project: project)
        TabsDataController.shared.addArticleToCurrentTab(article: article)
    
        self.tab = TabsDataController.shared.currentTab
        self.article = article
    }
    
    public func tappedBack() {
        
        guard let tab else {
            return
        }
        
        TabsDataController.shared.back(tab: tab)
    }
}

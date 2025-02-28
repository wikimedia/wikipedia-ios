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
    private let startShouldAddArticleToCurrentTab: Bool
    
    private var project: WikimediaProject? {
        guard let siteURL = articleURL.wmf_site,
              let project = WikimediaProject(siteURL: siteURL) else {
            return nil
        }
        return project
    }
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, source: ArticleSource, isRestoringState: Bool = false, needsAnimation: Bool = true, startShouldAddArticleToCurrentTab: Bool = true) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        self.source = source
        self.isRestoringState = isRestoringState
        self.needsAnimation = needsAnimation
        self.startShouldAddArticleToCurrentTab = startShouldAddArticleToCurrentTab
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
        if startShouldAddArticleToCurrentTab {
            addArticleToCurrentTab()
        }
        return true
    }
    
    private func addArticleToCurrentTab() {
        guard let title = articleURL.wmf_title,
              let project = project?.wmfProject else {
            return
        }
        
        let tabArticle: WMFData.Tab.Article = WMFData.Tab.Article(title: title, project: project)
        TabsDataController.shared.addArticleToCurrentTab(article: tabArticle)
    }
    
    public func removeArticleFromCurrentTab() {
        guard let title = articleURL.wmf_title,
              let project = project?.wmfProject else {
            return
        }
        
        let tabArticle: WMFData.Tab.Article = WMFData.Tab.Article(title: title, project: project)
        TabsDataController.shared.removeArticleFromCurrentTab(article: tabArticle)
    }
}

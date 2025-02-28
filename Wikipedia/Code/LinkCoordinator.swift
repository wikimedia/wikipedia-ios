import WMF
import WMFData

final class LinkCoordinator: Coordinator {
    
    enum Destination {
        case article
        case unknown
    }
    
    let navigationController: UINavigationController
    private let url: URL
    private let dataStore: MWKDataStore
    var theme: Theme
    private let articleSource: ArticleSource
    private let fromDeepLink: Bool
    
    init(navigationController: UINavigationController, url: URL, dataStore: MWKDataStore?, theme: Theme, articleSource: ArticleSource, fromDeepLink: Bool = false) {
        self.navigationController = navigationController
        self.url = url
        self.dataStore = dataStore ?? MWKDataStore.shared()
        self.theme = theme
        self.articleSource = articleSource
        self.fromDeepLink = fromDeepLink
    }
    
    @discardableResult
    func start() -> Bool {
        
        let destination = self.destination(for: url)
        
        switch destination {
        case .article:
            if !WMFDeveloperSettingsDataController.shared.tabsDeepLinkInCurrentTab && fromDeepLink {
                TabsDataController.shared.currentTab = nil
            }
            let articleCoordinator = ArticleCoordinator(
                navigationController: navigationController,
                articleURL: url,
                dataStore: dataStore,
                theme: theme,
                source: articleSource)
            return articleCoordinator.start()
        case .unknown:
            return false
        }
    }
    
    private func destination(for url: URL) -> Destination {
        
        guard let siteURL = url.wmf_site,
              let project = WikimediaProject(siteURL: siteURL) else {
            return .unknown
        }
        
        // Copied from Router.swift's destinationForHostURL
        
        let canonicalURL = url.canonical
        
        guard let path = canonicalURL.wikiResourcePath else {
            return .unknown
        }
        
        let language = project.languageCode ?? "en"
        
        let namespaceAndTitle = path.namespaceAndTitleOfWikiResourcePath(with: language)
        let namespace = namespaceAndTitle.0
        let title = namespaceAndTitle.1
        
        switch namespace {
        case .main:
            guard project.mainNamespaceGoesToNativeArticleView else {
                return .unknown
            }
            
            // Do not navigate donate thankyou page to article view
            guard let host = url.host,
                  host != "thankyou.wikipedia.org" else {
                return .unknown
            }
            
            let isMainPageTitle = WikipediaURLTranslations.isMainpageTitle(title, in: language)
            
            guard !isMainPageTitle else {
                return .unknown
            }
            
            return .article
        default:
            return .unknown
        }
    }
}

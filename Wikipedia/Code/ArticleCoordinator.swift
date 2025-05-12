import WMF
import WMFData
import CocoaLumberjackSwift

enum TabConfig {
    case appendArticleAndAssignCurrentTab // Default navigation
    case appendArticleAndAssignNewTabAndSetToCurrent // Open in new tab long press,
    case assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers) // Tapping tab from tabs overview
    case assignNewTabAndSetToCurrent // Tapping add tab from tabs overview
    case assignCurrentTab // Tapping main tab grid item
 }

final class ArticleCoordinator: NSObject, Coordinator {
    let navigationController: UINavigationController
    private(set) var articleURL: URL
    private let dataStore: MWKDataStore
    var theme: Theme
    private let needsAnimation: Bool
    
    private let source: ArticleSource
    private let isRestoringState: Bool
    private let previousPageViewObjectID: NSManagedObjectID?
    
    // Article Tabs Properties
    private let tabConfig: TabConfig
    private(set) var tabIdentifier: UUID?
    private(set) var tabItemIdentifier: UUID?
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, needsAnimation: Bool = true, source: ArticleSource, isRestoringState: Bool = false, previousPageViewObjectID: NSManagedObjectID? = nil, tabConfig: TabConfig = .appendArticleAndAssignCurrentTab) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        self.needsAnimation = needsAnimation
        self.source = source
        self.isRestoringState = isRestoringState
        self.previousPageViewObjectID = previousPageViewObjectID
        self.tabConfig = tabConfig
        super.init()
    }
    
    @discardableResult
    func start() -> Bool {
        
        // assign language variant code if needed (taken from AppVC's processUserActivity method)
        if articleURL.wmf_languageVariantCode == nil {
            articleURL.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(articleURL.wmf_languageCode)
        }
        
        guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source, previousPageViewObjectID: previousPageViewObjectID) else {
            return false
        }
        articleVC.isRestoringState = isRestoringState
        
        trackArticleTab(articleViewController: articleVC)
        
        navigationController.pushViewController(articleVC, animated: needsAnimation)
        
        return true
    }
    
    private func trackArticleTab(articleViewController: ArticleViewController) {
        
        guard let tabsDataController = WMFArticleTabsDataController.shared else {
            return
        }
        
        guard tabsDataController.shouldShowArticleTabs else {
            return
        }
        
        articleViewController.coordinator = self

        // Handle Article Tabs
        Task {
            guard let title = articleURL.wmf_title,
                  let siteURL = articleURL.wmf_site,
                  let wmfProject = WikimediaProject(siteURL: siteURL)?.wmfProject else {
                return
            }

            let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: wmfProject)
            do {
                guard let tabsDataController = WMFArticleTabsDataController.shared else {
                    DDLogError("Failed to handle tab configuration: Missing data controller")
                    return
                }
                switch tabConfig {
                case .appendArticleAndAssignCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    let identifiers = try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier)
                    self.tabIdentifier = identifiers.tabIdentifier
                    self.tabItemIdentifier = identifiers.tabItemIdentifier
                case .appendArticleAndAssignNewTabAndSetToCurrent:
                    let identifiers = try await tabsDataController.createArticleTab(initialArticle: article, setAsCurrent: true)
                    self.tabIdentifier = identifiers.tabIdentifier
                    self.tabItemIdentifier = identifiers.tabItemIdentifier
                case .assignParticularTabAndSetToCurrent(let identifiers):
                    try await tabsDataController.setTabAsCurrent(tabIdentifier: identifiers.tabIdentifier)
                    self.tabIdentifier = identifiers.tabIdentifier
                    self.tabItemIdentifier = identifiers.tabItemIdentifier
                case .assignCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    self.tabIdentifier = tabIdentifier
                case .assignNewTabAndSetToCurrent:
                    let identifiers = try await tabsDataController.createArticleTab(initialArticle: nil, setAsCurrent: true)
                    self.tabIdentifier = identifiers.tabIdentifier
                    self.tabItemIdentifier = identifiers.tabItemIdentifier
                }
            } catch {
                DDLogError("Failed to handle tab configuration: \(error)")
            }
        }
    }
    
    // Cleanup needed when tapping Back button
    func syncTabsOnArticleAppearance() {
        guard let tabsDataController = WMFArticleTabsDataController.shared else {
            return
        }
        
        guard tabsDataController.shouldShowArticleTabs else {
            return
        }
        
        guard let tabIdentifier,
              let tabItemIdentifier else {
            return
        }
        
        Task {
            try await tabsDataController.setTabItemAsCurrent(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
            try await tabsDataController.deleteEmptyTabs()
        }
    }
}

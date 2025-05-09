import WMF
import WMFData
import CocoaLumberjackSwift

enum TabConfig {
    case appendArticleAndAssignCurrentTab
    case appendArticleAndAssignNewTabAndSetToCurrent
    case appendArticleAndAssignParticularTabAndSetToCurrent(UUID) // may not need this
    case assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers)
    case assignNewTabAndSetToCurrent
    case assignCurrentTab
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
        
        guard let tabsDataController = try? WMFArticleTabsDataController() else {
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
                let tabsDataController = try WMFArticleTabsDataController()
                switch tabConfig {
                case .appendArticleAndAssignCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    let identifiers = try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier)
                    self.tabIdentifier = identifiers.articleTabIdentifier
                    self.tabItemIdentifier = identifiers.articleTabItemIdentifier
                case .appendArticleAndAssignNewTabAndSetToCurrent:
                    let identifiers = try await tabsDataController.createArticleTab(initialArticle: article, setAsCurrent: true)
                    self.tabIdentifier = identifiers.articleTabIdentifier
                    self.tabItemIdentifier = identifiers.articleTabItemIdentifier
                case .appendArticleAndAssignParticularTabAndSetToCurrent(let tabIdentifier):
                    let identifiers = try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier, setAsCurrent: true)
                    self.tabIdentifier = identifiers.articleTabIdentifier
                    self.tabItemIdentifier = identifiers.articleTabItemIdentifier
                case .assignParticularTabAndSetToCurrent(let identifiers):
                    try await tabsDataController.setTabAsCurrent(tabIdentifier: identifiers.articleTabIdentifier)
                    self.tabIdentifier = identifiers.articleTabIdentifier
                    self.tabItemIdentifier = identifiers.articleTabItemIdentifier
                case .assignCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    self.tabIdentifier = tabIdentifier
                case .assignNewTabAndSetToCurrent:
                    
                    let createNewTabBlock = { [weak self] in
                        guard let self else { return }
                        let identifiers = try await tabsDataController.createArticleTab(initialArticle: nil, setAsCurrent: true)
                        self.tabIdentifier = identifiers.articleTabIdentifier
                        self.tabItemIdentifier = identifiers.articleTabItemIdentifier
                    }
                    
                    let tabsCount = try await tabsDataController.tabsCount()
                    
                    if tabsCount == 1 {
                        let currentTabIdentifier = try await tabsDataController.currentTabIdentifier()
                        let currentTab = try await tabsDataController.fetchTab(tabIdentfiier: currentTabIdentifier)
                        
                        // They tapped new tab on an empty state. Instead just assign the current tab, so we don't have this awkward additional empty tab.
                        // To repro this weirdness: start from a totally fresh state, like Explore. You will see the single Main Page grid item. Then tap the + button.
                        if currentTab.articles.count == 0 {
                            self.tabIdentifier = currentTabIdentifier
                        } else {
                            try await createNewTabBlock()
                        }
                        
                    } else {
                        try await createNewTabBlock()
                    }
                }
            } catch {
                DDLogError("Failed to handle tab configuration: \(error)")
            }
        }
    }
    
    // Cleanup needed when tapping Back button
    func syncTabsOnArticleAppearance() {
        guard let tabsDataController = try? WMFArticleTabsDataController() else {
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

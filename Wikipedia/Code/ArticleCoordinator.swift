import WMF
import WMFData
import CocoaLumberjackSwift

enum TabConfig {
    case appendArticleAndAssignCurrentTab
    case appendArticleAndAssignNewTabAndSetToCurrent
    case appendArticleAndAssignParticularTabAndSetToCurrent(UUID) // may not need this
    case assignParticularTabAndSetToCurrent(UUID)
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
    private var previousNavigationControllerDelegate: UINavigationControllerDelegate?
    private let tabConfig: TabConfig
    private(set) var tabIdentifier: UUID?
    
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
        previousNavigationControllerDelegate = navigationController.delegate
        navigationController.delegate = self
        
        // Handle Article Tabs
        Task {
            guard let title = articleURL.wmf_title,
                  let siteURL = articleURL.wmf_site,
                  let wmfProject = WikimediaProject(siteURL: siteURL)?.wmfProject else {
                return
            }

            let article = WMFArticleTabsDataController.WMFArticle(title: title, project: wmfProject)
            do {
                let tabsDataController = try WMFArticleTabsDataController()
                switch tabConfig {
                case .appendArticleAndAssignCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier)
                    self.tabIdentifier = tabIdentifier
                case .appendArticleAndAssignNewTabAndSetToCurrent:
                    let tabIdentifier = try await tabsDataController.createArticleTab(initialArticle: article, setAsCurrent: true)
                    self.tabIdentifier = tabIdentifier
                case .appendArticleAndAssignParticularTabAndSetToCurrent(let tabIdentifier):
                    try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier, setAsCurrent: true)
                    self.tabIdentifier = tabIdentifier
                case .assignParticularTabAndSetToCurrent(let tabIdentifier):
                    try await tabsDataController.setTabAsCurrent(tabIdentifier: tabIdentifier)
                    self.tabIdentifier = tabIdentifier
                case .assignCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    self.tabIdentifier = tabIdentifier
                case .assignNewTabAndSetToCurrent:
                    
                    let createNewTabBlock = { [weak self] in
                        guard let self else { return }
                        let newTabIdentifier = try await tabsDataController.createArticleTab(initialArticle: nil, setAsCurrent: true)
                        self.tabIdentifier = newTabIdentifier
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
}

// MARK: - UINavigationControllerDelegate

extension ArticleCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
         // Detect if ArticleViewController was popped (back button pressed)
         guard let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
               !(navigationController.viewControllers.contains(fromVC)),
               let fromArticleVC = fromVC as? ArticleViewController else {
             return
         }
         
         Task {
             do {
                 guard let tabIdentifier = self.tabIdentifier else { return }
                 let tabsDataController = try WMFArticleTabsDataController()
                 
                 try await tabsDataController.removeLastArticleFromTab(tabIdentifier: tabIdentifier)
             } catch {
                 DDLogError("Failed to remove last article from tab: \(error)")
             }
         }
         
         // Restore previous delegate
         navigationController.delegate = previousNavigationControllerDelegate
         previousNavigationControllerDelegate = nil
     }
}

import WMF
import WMFData
import CocoaLumberjackSwift

enum TabConfig {
    case appendArticleToCurrentTab
    case appendArticleToNewTab
    case appendArticleToTab(UUID)
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
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, needsAnimation: Bool = true, source: ArticleSource, isRestoringState: Bool = false, previousPageViewObjectID: NSManagedObjectID? = nil, tabConfig: TabConfig = .appendArticleToCurrentTab) {
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
                case .appendArticleToCurrentTab:
                    let tabIdentifier = try await tabsDataController.currentTabIdentifier()
                    try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier)
                    self.tabIdentifier = tabIdentifier
                case .appendArticleToNewTab:
                    let tabIdentifier = try await tabsDataController.createArticleTab(initialArticle: article, setAsCurrent: true)
                    self.tabIdentifier = tabIdentifier
                case .appendArticleToTab(let tabIdentifier):
                    try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier, setAsCurrent: true)
                    self.tabIdentifier = tabIdentifier
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
               fromVC is ArticleViewController else {
             return
         }
         
         // Remove last article from tab
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

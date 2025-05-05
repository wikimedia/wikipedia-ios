import WMF
import WMFData
import CocoaLumberjackSwift

enum TabConfig {
    case appendArticleToCurrentTab
    case appendArticleToOtherTab(UUID)
    case appendArticleToNewTab
}

final class ArticleCoordinator: NSObject, Coordinator, UINavigationControllerDelegate {
    let navigationController: UINavigationController
    private(set) var articleURL: URL
    private let dataStore: MWKDataStore
    var theme: Theme
    private let source: ArticleSource
    private let isRestoringState: Bool
    private let previousPageViewObjectID: NSManagedObjectID?
    private var previousNavigationControllerDelegate: UINavigationControllerDelegate?
    private let tabConfig: TabConfig
    private(set) var currentTabIdentifier: UUID?
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, source: ArticleSource, isRestoringState: Bool = false, previousPageViewObjectID: NSManagedObjectID? = nil, tabConfig: TabConfig = .appendArticleToCurrentTab) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
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
        articleVC.coordinator = self
        previousNavigationControllerDelegate = navigationController.delegate
        navigationController.delegate = self
        navigationController.pushViewController(articleVC, animated: true)

        // Handle tab configuration
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
                    self.currentTabIdentifier = tabIdentifier
                case .appendArticleToOtherTab(let tabId):
                    try await tabsDataController.appendArticle(article, toTabIdentifier: tabId)
                    self.currentTabIdentifier = tabId
                case .appendArticleToNewTab:
                    let newTabId = try await tabsDataController.createArticleTab(initialArticle: article, setAsCurrent: true)
                    self.currentTabIdentifier = newTabId
                }
            } catch {
                DDLogError("Failed to handle tab configuration: \(error)")
            }
        }

        return true
    }
    
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
                guard let currentTabIdentifier = self.currentTabIdentifier else { return }
                let tabsDataController = try WMFArticleTabsDataController()
                
                try await tabsDataController.removeLastArticleFromTab(tabIdentifier: currentTabIdentifier)
            } catch {
                DDLogError("Failed to remove last article from tab: \(error)")
            }
        }
        
        // Restore previous delegate
        navigationController.delegate = previousNavigationControllerDelegate
        previousNavigationControllerDelegate = nil
    }
}

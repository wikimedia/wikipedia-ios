import WMF
import WMFData
import WMFComponents
import CocoaLumberjackSwift

enum ArticleTabConfig {
    case appendArticleAndAssignCurrentTab // Default navigation
    case appendArticleAndAssignCurrentTabAndRemovePrecedingMainPage // When tapping + add tab > focused search bar experiment. Remove preceding Main Page in navigation stack before navigating.
    case appendArticleAndAssignCurrentTabAndCleanoutFutureArticles // Navigating from article blue link or article search
    case appendArticleAndAssignNewTabAndSetToCurrent // Open in new tab long press
    case assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers) // Tapping tab from tabs overview
    case assignNewTabAndSetToCurrent // Tapping add tab from tabs overview - Main Page
    case adjacentArticleInTab(WMFArticleTabsDataController.Identifiers) // Tapping 'forward in tab' / 'back in tab' buttons on article toolbar
 }

@MainActor
protocol ArticleTabCoordinating: AnyObject {
    func trackArticleTab(articleViewController: ArticleViewController) async
    func syncTabsOnArticleAppearance()
    var articleURL: URL? { get }
    var tabConfig: ArticleTabConfig { get }
    var tabIdentifier: UUID? { get set }
    var tabItemIdentifier: UUID? { get set }
    var navigationController: UINavigationController { get }
    var theme: Theme { get }
}

@MainActor
extension ArticleTabCoordinating {
    
    func trackArticleTab(articleViewController: ArticleViewController) async {
        
        articleViewController.coordinator = self
        
        let tabsDataController = WMFArticleTabsDataController.shared

        guard let title = articleURL?.wmf_title,
              let siteURL = articleURL?.wmf_site,
              let wmfProject = WikimediaProject(siteURL: siteURL)?.wmfProject,
              let articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }

        let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: wmfProject, articleURL: articleURL)
        do {
            
            // Reassign tabConfig if needed
            // If current tabs count is at 500, do not create any new tabs. Instead append article to current tab.
            var tabConfig = self.tabConfig
            switch tabConfig {
            case .assignNewTabAndSetToCurrent, .appendArticleAndAssignNewTabAndSetToCurrent:
                let tabsCount = try await tabsDataController.tabsCount()
                let tabsMax = tabsDataController.tabsMax
                if tabsCount >= tabsMax {
                    tabConfig = .appendArticleAndAssignCurrentTab
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        WMFAlertManager.sharedInstance.showBottomWarningAlertWithMessage(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil,  buttonTitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousAlerts: true)
                    }
                }
            default:
                break
            }
            
            // Reassign tabConfig if needed
            // If there is no current tab but we were expecting one, create a new tab instead
            let currentTabIdentifier = try await tabsDataController.currentTabIdentifier()
            if currentTabIdentifier == nil {
                    switch tabConfig {
                    case .appendArticleAndAssignCurrentTabAndCleanoutFutureArticles,
                            .appendArticleAndAssignCurrentTab,
                            .appendArticleAndAssignCurrentTabAndRemovePrecedingMainPage:
                        tabConfig = .appendArticleAndAssignNewTabAndSetToCurrent
                    default:
                        break
                    }
           }
            
            switch tabConfig {
            case .appendArticleAndAssignCurrentTabAndCleanoutFutureArticles:
                guard let tabIdentifier = try await tabsDataController.currentTabIdentifier() else {
                    DDLogError("Expected current tab identifier")
                    return
                }
                let identifiers = try await tabsDataController.appendArticle(article, toTabIdentifier: tabIdentifier, needsCleanoutOfFutureArticles: true)
                self.tabIdentifier = identifiers.tabIdentifier
                self.tabItemIdentifier = identifiers.tabItemIdentifier
            case .appendArticleAndAssignCurrentTab, .appendArticleAndAssignCurrentTabAndRemovePrecedingMainPage:
                guard let tabIdentifier = try await tabsDataController.currentTabIdentifier() else {
                    DDLogError("Expected current tab identifier")
                    return
                }
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
            case .assignNewTabAndSetToCurrent:
                let identifiers = try await tabsDataController.createArticleTab(initialArticle: nil, setAsCurrent: true)
                self.tabIdentifier = identifiers.tabIdentifier
                self.tabItemIdentifier = identifiers.tabItemIdentifier
            case .adjacentArticleInTab(let identifiers):
                self.tabIdentifier = identifiers.tabIdentifier
                self.tabItemIdentifier = identifiers.tabItemIdentifier
            }
        } catch {
            DDLogError("Failed to handle tab configuration: \(error)")
        }
    }
    
    // Cleanup needed when tapping Back button
    func syncTabsOnArticleAppearance() {
        let tabsDataController = WMFArticleTabsDataController.shared

        guard let tabIdentifier,
              let tabItemIdentifier else {
            return
        }
        
        Task {
            try await tabsDataController.setTabItemAsCurrent(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
            try await tabsDataController.deleteEmptyTabs()
        }
    }

    @MainActor
    func prepareToShowTabsOverview(articleViewController: ArticleViewController, _ dataStore: MWKDataStore) {
        articleViewController.showTabsOverview = { [weak navigationController, weak self] in
            guard let navController = navigationController, let self = self else { return }

            TabsCoordinatorManager.shared.presentTabsOverview(
                from: navController,
                theme: theme,
                dataStore: dataStore
            )
        }
    }
}

final class ArticleCoordinator: NSObject, Coordinator, ArticleTabCoordinating {
    let navigationController: UINavigationController
    private(set) var articleURL: URL?
    private let dataStore: MWKDataStore
    var theme: Theme
    private let needsAnimation: Bool
    
    private let source: ArticleSource
    private let isRestoringState: Bool
    private let previousPageViewObjectID: NSManagedObjectID?
    
    // Article Tabs Properties
    let tabConfig: ArticleTabConfig
    var tabIdentifier: UUID?
    var tabItemIdentifier: UUID?
    var needsFocusOnSearch: Bool
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, needsAnimation: Bool = true, source: ArticleSource, isRestoringState: Bool = false, previousPageViewObjectID: NSManagedObjectID? = nil, tabConfig: ArticleTabConfig = .appendArticleAndAssignCurrentTab, needsFocusOnSearch: Bool = false) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        self.needsAnimation = needsAnimation
        self.source = source
        self.isRestoringState = isRestoringState
        self.previousPageViewObjectID = previousPageViewObjectID
        self.tabConfig = tabConfig
        self.needsFocusOnSearch = needsFocusOnSearch
        super.init()
    }
    
    @MainActor @discardableResult
    func start() -> Bool {
        
        guard let articleURL else {
            return false
        }
        
        // assign language variant code if needed (taken from AppVC's processUserActivity method)
        if articleURL.wmf_languageVariantCode == nil {
            self.articleURL?.wmf_languageVariantCode = dataStore.languageLinkController .swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(articleURL.wmf_languageCode)
        }
        
        guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source, previousPageViewObjectID: previousPageViewObjectID, needsFocusOnSearch: needsFocusOnSearch) else {
            return false
        }
        articleVC.isRestoringState = isRestoringState
        prepareToShowTabsOverview(articleViewController: articleVC, dataStore)
        
        Task {
            await trackArticleTab(articleViewController: articleVC)
            
            Task { @MainActor in
                switch tabConfig {
                case .adjacentArticleInTab:
                    var viewControllers = navigationController.viewControllers
                    if viewControllers.count > 0 {
                        viewControllers.removeLast()
                    }
                    
                    viewControllers.append(articleVC)
                    navigationController.setViewControllers(viewControllers, animated: needsAnimation)
                case .appendArticleAndAssignCurrentTabAndRemovePrecedingMainPage:
                    
                    var viewControllers = navigationController.viewControllers
                    if viewControllers.count > 0,
                       let lastArticle = viewControllers.last as? ArticleViewController,
                       lastArticle.articleURL.wmf_title == "Main Page" {
                        viewControllers.removeLast()
                    }
                    
                    viewControllers.append(articleVC)
                    navigationController.setViewControllers(viewControllers, animated: needsAnimation)
                    
                default:
                    navigationController.pushViewController(articleVC, animated: needsAnimation)

                }
            }
        }
        
        return true
    }

}

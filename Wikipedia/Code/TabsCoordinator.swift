import WMFComponents
import WMFData

final class TabsCoordinator: Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    var theme: Theme
    
    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }
    
    @discardableResult
    func start() -> Bool {
        
        let viewModel = WMFTabsViewModel(tappedAddTabAction: { [weak self] in
            self?.tappedAddTab()
        }, tappedTabAction: { [weak self] tab, alreadyCurrentTab in
            self?.tappedTab(tab: tab, alreadyCurrentTab: alreadyCurrentTab)
        }, tappedCloseTabAction: { [weak self] tab, currentTabClosed in
            self?.tappedCloseTab(tab: tab, currentTabClosed: currentTabClosed)
        })
        let tabsHostingController = WMFTabsHostingController(viewModel: viewModel)
        let navVC = WMFComponentNavigationController(rootViewController: tabsHostingController)
        self.navigationController.present(navVC, animated: true)
        return true
    }
    
    private func tappedAddTab() {
        
        if WMFDeveloperSettingsDataController.shared.tabsDoNotPreserveBackHistory {
            guard let rootVC = navigationController.viewControllers.first else {
                return
            }
            
            let rootExploreVC = rootVC as? ExploreViewController
            let rootSearchVC = rootVC as? SearchViewController
            var newSearchVC: SearchViewController?
            
            // Explore and Search tabs already have search bar, so just pop back and focus
            if rootExploreVC != nil {
                navigationController.popToRootViewController(animated: false)
            } else if rootSearchVC != nil {
                navigationController.popToRootViewController(animated: false)
            } else {
                // If root is not Explore or Search tab, create new search on top of root
                newSearchVC = SearchViewController(source: .unknown, customArticleCoordinatorNavigationController: navigationController)
                newSearchVC?.apply(theme: theme)
                newSearchVC?.dataStore = dataStore
                newSearchVC?.needsCenteredTitle = true
                
                if let newSearchVC {
                    navigationController.setViewControllers([rootVC, newSearchVC], animated: false)
                }
            }
            
            // then dismiss tabs modal
            navigationController.dismiss(animated: true) {
                
                // Focuses search bar after appearance
                if let rootExploreVC {
                    rootExploreVC.focusSearchBar()
                } else if let rootSearchVC {
                    rootSearchVC.focusSearchBar()
                } else if let newSearchVC {
                    newSearchVC.focusSearchBar()
                }
                
            }
        } else {
            let newSearchVC = SearchViewController(source: .unknown, customArticleCoordinatorNavigationController: navigationController)
            newSearchVC.apply(theme: theme)
            newSearchVC.dataStore = dataStore
            newSearchVC.needsCenteredTitle = true
            
            navigationController.pushViewController(newSearchVC, animated: false)
            
            navigationController.dismiss(animated: true) {
                newSearchVC.focusSearchBar()
            }
        }
    }
    
    private func tappedTab(tab: WMFData.Tab, alreadyCurrentTab: Bool) {
        
        guard !alreadyCurrentTab else {
            navigationController.dismiss(animated: true)
            return
        }
        
        if WMFDeveloperSettingsDataController.shared.tabsDoNotPreserveBackHistory {
            
            guard tab.currentArticleIndex <= tab.articles.count - 1 else {
                assertionFailure("Unexpected currentArticleIndex")
                return
            }
            
            // Add on top of root
            guard let firstVC = navigationController.viewControllers.first else {
                return
            }
            
            // first reset navigation stack underneath modal
            navigationController.setViewControllers([firstVC], animated: false)
            
            let articlesToPush = tab.articles[0...tab.currentArticleIndex]
            
            for article in articlesToPush {
                guard let articleTitle = article.title.denormalizedPageTitle,
                      let articleURL = URL(string: "https://en.wikipedia.org/wiki/\(articleTitle)") else {
                    continue
                }
                
                let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: Theme.light, source: .undefined, needsAnimation: false, tab: tab, article: article)
                articleCoordinator.start()
            }
            
            // then dismiss tabs modal
            navigationController.dismiss(animated: true)

        } else {
            
            guard tab.currentArticleIndex <= tab.articles.count - 1 else {
                assertionFailure("Unexpected currentArticleIndex")
                return
            }
            
            let articlesToPush = tab.articles[0...tab.currentArticleIndex]
            
            for article in articlesToPush {
                guard let articleTitle = article.title.denormalizedPageTitle,
                      let articleURL = URL(string: "https://en.wikipedia.org/wiki/\(articleTitle)") else {
                    continue
                }

                let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: Theme.light, source: .undefined, needsAnimation: false, tab: tab, article: article)
                articleCoordinator.start()
            }
            
            navigationController.dismiss(animated: true)
        }
    }
    
    private func tappedCloseTab(tab: WMFData.Tab, currentTabClosed: Bool) {
        
        if WMFDeveloperSettingsDataController.shared.tabsDoNotPreserveBackHistory {
            if currentTabClosed {
                // reset navigation stack underneath modal
                navigationController.popToRootViewController(animated: false)
            }
        } else {
            // do nothing?
        }
    }
}

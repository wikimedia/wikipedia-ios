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
        
        if WMFDeveloperSettingsDataController.shared.tabsPreserveRabbitHole {
            let newSearchVC = SearchViewController(source: .unknown, customArticleCoordinatorNavigationController: navigationController)
            newSearchVC.apply(theme: theme)
            newSearchVC.dataStore = dataStore
            newSearchVC.needsCenteredTitle = true
            
            navigationController.pushViewController(newSearchVC, animated: false)
            
            navigationController.dismiss(animated: true) {
                newSearchVC.focusSearchBar()
            }
        } else {
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
        }
    }
    
    private func tappedTab(tab: WMFData.Tab, alreadyCurrentTab: Bool) {
        
        guard !alreadyCurrentTab else {
            navigationController.dismiss(animated: true)
            return
        }
        
        if WMFDeveloperSettingsDataController.shared.tabsPreserveRabbitHole {
            
            for article in tab.articles {
                guard let articleTitle = article.title.denormalizedPageTitle,
                      let articleURL = URL(string: "https://en.wikipedia.org/wiki/\(articleTitle)") else {
                    continue
                }
                
                // Article is already a part of a tab, no need to add it again.
                let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: Theme.light, source: .undefined, needsAnimation: false, startShouldAddArticleToCurrentTab: false)
                articleCoordinator.start()
            }
            
            navigationController.dismiss(animated: true)
            
        } else {
            
            // Add on top of root
            guard let firstVC = navigationController.viewControllers.first else {
                return
            }
            
            // first reset navigation stack underneath modal
            navigationController.setViewControllers([firstVC], animated: false)
            
            for article in tab.articles {
                guard let articleTitle = article.title.denormalizedPageTitle,
                      let articleURL = URL(string: "https://en.wikipedia.org/wiki/\(articleTitle)") else {
                    continue
                }
                
                // Kick off coordinator to add to stack. Article is already a part of a tab, no need to add it again.
                let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: Theme.light, source: .undefined, needsAnimation: false, startShouldAddArticleToCurrentTab: false)
                articleCoordinator.start()
            }
            
            // then dismiss tabs modal
            navigationController.dismiss(animated: true)
        }
    }
    
    private func tappedCloseTab(tab: WMFData.Tab, currentTabClosed: Bool) {
        
        if WMFDeveloperSettingsDataController.shared.tabsPreserveRabbitHole {
            // do nothing?
        } else {
            if currentTabClosed {
                // reset navigation stack underneath modal
                navigationController.popToRootViewController(animated: false)
            }
        }
    }
}

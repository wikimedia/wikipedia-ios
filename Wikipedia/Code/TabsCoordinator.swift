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
    
    func start() {
        
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
    }
    
    private func tappedAddTab() {
        
        guard let rootVC = navigationController.viewControllers.first else {
            return
        }
        
        let rootExploreVC = rootVC as? ExploreViewController
        let rootSearchVC = rootVC as? SearchViewController
        var newSearchVC: SearchViewController?
        
        // User is unintentionally clearing their nav stack, so do not remove articles from tab stack
        for viewController in navigationController.viewControllers {
            if let articleVC = viewController as? ArticleViewController {
                articleVC.removeFromTabUponDisappearance = false
            }
        }
        
        // Create new search on top of root
        if rootExploreVC != nil {
            navigationController.popToRootViewController(animated: false)
        } else if rootSearchVC != nil {
            navigationController.popToRootViewController(animated: false)
        } else {
            newSearchVC = SearchViewController(source: .unknown, hidesBottomBarWhenPushed: true)
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
    
    private func tappedTab(tab: WMFData.Tab, alreadyCurrentTab: Bool) {
        
        guard !alreadyCurrentTab else {
            navigationController.dismiss(animated: true)
            return
        }
        
        // Add on top of root
        guard let firstVC = navigationController.viewControllers.first else {
            return
        }
        
        var newStack: [UIViewController] = [firstVC]
        
        for article in tab.articles {
            guard let articleTitle = article.title.denormalizedPageTitle,
                  let articleURL = URL(string: "https://en.wikipedia.org/wiki/\(articleTitle)") else {
                continue
            }
            
            let articleVC = ArticleViewController(articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: Theme.light, source: .undefined)!
            newStack.append(articleVC)
        }
        
        // first reset navigation stack underneath modal
        navigationController.setViewControllers(newStack, animated: false)
        
        // then dismiss tabs modal
        navigationController.dismiss(animated: true)
    }
    
    private func tappedCloseTab(tab: WMFData.Tab, currentTabClosed: Bool) {
        if currentTabClosed {
            // reset navigation stack underneath modal
            navigationController.popToRootViewController(animated: false)
        }
    }
}

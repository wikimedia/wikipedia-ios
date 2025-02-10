import WMFComponents
import WMFData

final class TabsCoordinator: Coordinator {
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        
        let viewModel = WMFTabsViewModel(tappedAddTabAction: {
            self.tappedAddTab()
        }, tappedTabAction: { tab in
            self.tappedTab(tab: tab)
        }, tappedCloseTabAction: { tab in
            self.tappedCloseTab(tab: tab)
        })
        let tabsHostingController = WMFTabsHostingController(viewModel: viewModel)
        let navVC = WMFComponentNavigationController(rootViewController: tabsHostingController)
        self.navigationController.present(navVC, animated: true)
    }
    
    private func tappedAddTab() {
        navigationController.dismiss(animated: true) { [weak self] in
            
            guard let self else { return }
            
            // Add main on top of root
            guard let firstVC = navigationController.viewControllers.first else {
                return
            }
            
            let articleVC = ArticleViewController(articleURL: URL(string: "https://en.wikipedia.org/wiki/Main_Page")!, dataStore: MWKDataStore.shared(), theme: Theme.light)!
            
            navigationController.setViewControllers([firstVC, articleVC], animated: true)
        }
    }
    
    private func tappedTab(tab: WMFData.Tab) {
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            
            // Add on top of root
            guard let firstVC = navigationController.viewControllers.first else {
                return
            }
            
            var newStack: [UIViewController] = [firstVC]
            
            for article in tab.articles {
                let articleVC = ArticleViewController(articleURL: URL(string: "https://en.wikipedia.org/wiki/\(article.title.replacing(" ", with: "_"))")!, dataStore: MWKDataStore.shared(), theme: Theme.light)!
                newStack.append(articleVC)
            }
            
            navigationController.setViewControllers(newStack, animated: true)
        }
        
    }
    
    private func tappedCloseTab(tab: WMFData.Tab) {
        
//        if TabsDataController.shared.currentTab == nil {
//            navigationController.dismiss(animated: true) {
//                self.navigationController.popToRootViewController(animated: true)
//            }
//        }
//        
//        
    }
}

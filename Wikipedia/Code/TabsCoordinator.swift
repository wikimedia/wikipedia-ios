import WMFComponents
import WMFData

final class TabsCoordinator: Coordinator {
    
    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    
    init(navigationController: UINavigationController, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.dataStore = dataStore
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
        
        // Add main on top of root
        guard let firstVC = navigationController.viewControllers.first,
        let mainPageURL = URL(string: "https://en.wikipedia.org/wiki/Main_Page"),
        let mainVC = ArticleViewController(articleURL: mainPageURL, dataStore: dataStore, theme: Theme.light, source: .undefined) else {
            return
        }
        
        // first reset navigation stack underneath modal
        navigationController.setViewControllers([firstVC, mainVC], animated: false)
        
        // then dismiss tabs modal
        navigationController.dismiss(animated: true)
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

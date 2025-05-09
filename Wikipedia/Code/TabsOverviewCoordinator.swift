import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

final class TabsOverviewCoordinator: Coordinator {
    var navigationController: UINavigationController
    var theme: Theme
    let dataStore: MWKDataStore
    
    func start() -> Bool {
        if shouldShowEntryPoint() {
            presentTabs()
            return true
        } else {
            return false
        }
    }
    
    func shouldShowEntryPoint() -> Bool {
        guard let dataController = try? WMFArticleTabsDataController() else {
            return false
        }
        return dataController.shouldShowArticleTabs
    }
    
    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }
    
    private func presentTabs() {
        
        let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void = { [weak self] tab in
            self?.tappedTab(tab)
        }
        
        let didTapAddTab: () -> Void = { [weak self] in
            self?.tappedAddTab()
        }
        
        let didTapMainTab: () -> Void = { [weak self] in
            self?.tappedMainTab()
        }
        
        let viewModel = WMFTabsOverviewViewModel(didTapTab: didTapTab, didTapMain: didTapMainTab, didTapAddTab: didTapAddTab)
        
        let vc = WMFTabsOverviewViewController(viewModel: viewModel)
        let navVC = WMFComponentNavigationController(rootViewController: vc, modalPresentationStyle: .overFullScreen)

        navigationController.present(navVC, animated: true, completion: nil)
    }
    
    private func tappedTab(_ tab: WMFArticleTabsDataController.WMFArticleTab) {
        
        // If navigation controller is already displaying tab, just dismiss without pushing on any more tabs.
        if let displayedArticleViewController = navigationController.viewControllers.last as? ArticleViewController,
           let displayedTabIdentifier = displayedArticleViewController.coordinator?.tabIdentifier {
            if displayedTabIdentifier == tab.identifier {
                navigationController.dismiss(animated: true)
                return
            }
        }
        
        // for article in tab.articles {
        if let article = tab.articles.last {
            guard let siteURL = article.project.siteURL,
                  let articleURL = siteURL.wmf_URL(withTitle: article.title) else {
                // continue
                return
            }
            
            let tabConfig = TabConfig.assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers(articleTabIdentifier: tab.identifier, articleTabItemIdentifier: article.identifier))

            let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: tabConfig)
            articleCoordinator.start()
        }

        navigationController.dismiss(animated: true)
    }
    
    private func tappedAddTab() {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main_Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .assignNewTabAndSetToCurrent)
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }
    
    private func tappedMainTab() {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main_Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .assignCurrentTab)
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }

}

extension UIViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}

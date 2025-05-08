import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

final class TabsOverviewCoordinator: Coordinator {
    var navigationController: UINavigationController
    var theme: Theme
    let dataStore: MWKDataStore
    
    @discardableResult
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
        // Dummy tabs
        var tabs: [ArticleTab] = [
            ArticleTab(
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/e/e6/Policja_konna_Pozna%C5%84.jpg"),
                title: "Horse",
                subtitle: "Neigh neigh",
                description: nil,
                dateCreated: (Date.now - 10)),
            ArticleTab(
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/b/b6/Felis_catus-cat_on_snow.jpg"),
                title: "Cat",
                subtitle: "This article is all about cats and how cool they are. They often have several legs, and a nose. It's very impressive. They can jump, and some of them got long tails.",
                description: "Longer description, we will talk about cats. Here is information about cats. Lorem ipsum could be a cat name. I should start writing articles professionally, I am truly outstanding at this. I know everything about cats.",
                dateCreated: (Date.now - 5)),
            ArticleTab(
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9c/Meriones_unguiculatus_%28wild%29.jpg"),
                title: "Mongolian Gerbil",
                subtitle: nil,
                description: nil,
                dateCreated: Date.now - 20),
            ArticleTab(
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9c/Meriones_unguiculatus_%28wild%29.jpg"),
                title: "Gerbil",
                subtitle: nil,
                description: nil,
                dateCreated: Date.now - 500),
            ArticleTab(
                image: nil,
                title: "Oldest article",
                subtitle: "Here is a subtitle, this is the oldest article. My first added, I added it now minus 8295 because that's a great number I randomly picked.",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                dateCreated: Date.now - 8295),
            ArticleTab(
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9c/Meriones_unguiculatus_%28wild%29.jpg"),
                title: "Another article",
                subtitle: nil,
                description: nil,
                dateCreated: Date.now - 1),
            ArticleTab(
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9c/Meriones_unguiculatus_%28wild%29.jpg"),
                title: "Newest article",
                subtitle: nil,
                description: nil,
                dateCreated: Date.now)
        ]
        
        // Check if empty and insert main page prior to displaying
        if tabs.isEmpty {
            tabs = [
                ArticleTab(
                    image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9c/Meriones_unguiculatus_%28wild%29.jpg"),
                    title: "Main page",
                    subtitle: "Welcome to Wikipedia",
                    description: "This is just dummy data",
                    dateCreated: Date.now)
            ]
        }

        let articleTabsViewModel = WMFArticleTabsViewModel(articleTabs: tabs)
        let articleTabsView = WMFArticleTabsView(viewModel: articleTabsViewModel)
        
        let hostingController = WMFArticleTabsHostingController(rootView: articleTabsView, viewModel: articleTabsViewModel)
        let navVC = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .fullScreen)
        navigationController.present(navVC, animated: true, completion: nil)
    }
    
    private func tappedTab(_ tab: WMFArticleTabsDataController.WMFArticleTab) {
        
        guard !tab.isCurrent else {
            navigationController.dismiss(animated: true)
            return
        }
        
        for article in tab.articles {
            guard let siteURL = article.project.siteURL,
                  let articleURL = siteURL.wmf_URL(withTitle: article.title) else {
                continue
            }

            let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .appendArticleToTab(tab.identifier))
            articleCoordinator.start()
        }

        navigationController.dismiss(animated: true)
    }
    
    private func tappedNewTab() {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main_Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .appendArticleToNewTab)
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }

}

extension UIViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}

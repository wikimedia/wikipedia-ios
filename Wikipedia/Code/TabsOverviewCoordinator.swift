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
        let tabs: [ArticleTab] = [
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
                image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9c/Meriones_unguiculatus_%28wild%29.jpg"),
                title: "Oldest article",
                subtitle: nil,
                description: nil,
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
        let articleTabsViewModel = WMFArticleTabsViewModel(articleTabs: tabs)
        let articleTabsView = WMFArticleTabsView(viewModel: articleTabsViewModel)
        
        let hostingController = WMFArticleTabsHostingController(rootView: articleTabsView, viewModel: articleTabsViewModel)
        let navVC = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .fullScreen)
        navigationController.present(navVC, animated: true, completion: nil)
    }
}

extension UIViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}

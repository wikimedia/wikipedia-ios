import WMF
import UIKit
import CocoaLumberjackSwift
import WMFData

@objc(WMFNavigationStateController)
final class NavigationStateController: NSObject {
    private let dataStore: MWKDataStore
    private var theme = Theme.standard
    private weak var settingsNavController: UINavigationController?
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
    
    private typealias ViewController = NavigationState.ViewController
    private typealias Presentation = ViewController.Presentation
    private typealias Info = ViewController.Info
    
    @objc func saveNavigationState(for tabBarController: UITabBarController, in moc: NSManagedObjectContext) {
        
        guard let selectedNavigationController = tabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        guard visibleArticleViewController(for: selectedNavigationController) != nil else {
            moc.navigationState = nil
            return
        }
        
        let tabsDataController = WMFArticleTabsDataController.shared
        Task {
            do {
                try await tabsDataController.saveCurrentStateForLaterRestoration()
            } catch {
                DDLogError("Error saving article tabs for later restoration: \(error)")
            }
        }
    }
    
    /// Finds the topmost article from persisted NavigationState and pushes it onto navigationController
    @MainActor @objc func restoreLastArticle(for tabBarController: UITabBarController, in moc: NSManagedObjectContext, with theme: Theme, completion: @escaping () -> Void) {

        guard let selectedNavigationController = tabBarController.selectedViewController as? UINavigationController else {
            completion()
            return
        }
        
        let tabsDataController = WMFArticleTabsDataController.shared
        guard let tab = try? tabsDataController.loadCurrentStateForRestoration() ,
              let article = tab.articles.last,
              let siteURL = article.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: article.title) else {
            completion()
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: selectedNavigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined, isRestoringState: true, tabConfig: .assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers(tabIdentifier: tab.identifier, tabItemIdentifier: article.identifier)))
        let success = articleCoordinator.start()
        if success {
            try? tabsDataController.clearCurrentStateForRestoration()
        }
        completion()
    }
    
    func allPreservedArticleKeys(in moc: NSManagedObjectContext) -> [String]? {
        return moc.navigationState?.viewControllers.compactMap { $0.info?.articleKey }
    }
    
    private func pushOrPresent(_ viewController: UIViewController & Themeable, navigationController: UINavigationController, presentation: Presentation, animated: Bool = false) {
        viewController.apply(theme: theme)
        switch presentation {
        case .push:
            navigationController.pushViewController(viewController, animated: animated)
        case .modal:
            viewController.modalPresentationStyle = .overFullScreen
            navigationController.present(viewController, animated: animated)
        }
    }
    
    private func articleURL(from info: Info) -> URL? {
        guard
            let articleKey = info.articleKey,
            var articleURL = URL(string: articleKey)
        else {
            return nil
        }
        if let sectionAnchor = info.articleSectionAnchor, let articleURLWithFragment = articleURL.wmf_URL(withFragment: sectionAnchor) {
            articleURL = articleURLWithFragment
        }
        return articleURL
    }
    
    private func visibleArticleViewController(for viewController: UIViewController) -> ArticleViewController? {
        guard let navigationController = viewController as? UINavigationController else {
            return nil
        }
        
        if let presentedViewController = navigationController.presentedViewController {
            return visibleArticleViewController(for: presentedViewController)
        } else {
            if let lastViewController = navigationController.viewControllers.last as? ArticleViewController {
                return lastViewController
            }
        }
        
        return nil
    }
}

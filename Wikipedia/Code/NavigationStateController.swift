import WMF
import UIKit
import CocoaLumberjackSwift

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
        
        // Simple minimum state to save and restore: visible article view controller
        guard let selectedNavigationController = tabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        guard let articleViewController = visibleArticleViewController(for: selectedNavigationController) else {
            moc.navigationState = nil
            return
        }
        
        let info = Info(articleKey: articleViewController.articleURL.wmf_databaseKey)
        
        guard let stateToPersist = NavigationState.ViewController(kind: .article, presentation: .push, info: info) else {
            moc.navigationState = nil
            return
        }
        
        moc.navigationState = NavigationState(viewControllers: [stateToPersist], shouldAttemptLogin: false)
    }
    
    /// Finds the topmost article from persisted NavigationState and pushes it onto navigationController
    @objc func restoreLastArticle(for tabBarController: UITabBarController, in moc: NSManagedObjectContext, with theme: Theme, completion: @escaping () -> Void) {
        
        guard let selectedNavigationController = tabBarController.selectedViewController as? UINavigationController else {
            completion()
            return
        }
        
        guard let navigationState = moc.navigationState else {
            completion()
            return
        }
        
        self.theme = theme
        
        guard navigationState.viewControllers.count == 1,
        let articleViewControllerState = navigationState.viewControllers.last,
            let articleInfo = articleViewControllerState.info else {
                moc.navigationState = nil
                completion()
                return
            }
        
        
        guard let articleURL = articleURL(from: articleInfo) else {
            completion()
            return
        }
        
        let viewControllerToPush = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        
        guard let viewControllerToPush else {
            completion()
            return
        }
        
        viewControllerToPush.isRestoringState = true
        pushOrPresent(viewControllerToPush, navigationController: selectedNavigationController, presentation: .push)
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

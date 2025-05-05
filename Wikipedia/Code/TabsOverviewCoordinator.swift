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
        
        let hostingController = WMFTabsOverviewViewController()
        let navController = WMFComponentNavigationController(rootViewController: hostingController)
        navController.modalPresentationStyle = .overFullScreen

        navigationController.present(navController, animated: true, completion: nil)
    }
}

extension UIViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}

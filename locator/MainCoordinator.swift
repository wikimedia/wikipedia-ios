import Foundation
import UIKit

/// Main coordinator use for routing logic, can be extended with nested coordinatiors with app growth
final class MainCoordinator {
    private(set) var topViewController: UIViewController
    private let mainAssembly = MainAssembly()
    
    init() {
        let initialVC = LocationsViewController()
        self.topViewController = UINavigationController(rootViewController: initialVC)
        
        setAppearance()
    }
    
    private func setAppearance() {
        UINavigationBar.appearance().isTranslucent = true
    }
}

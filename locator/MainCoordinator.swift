import Foundation
import UIKit

/// Main coordinator use for routing logic, can be extended with nested coordinatiors with app growth
final class MainCoordinator {
    private(set) var topViewController: UIViewController
    private let mainAssembly = MainAssembly()
    
    init() {
        let presenter = LocationsPresenterImpl(mainAssembly) { [weak mainAssembly] output in
            switch output {
            case .select(let location):
                mainAssembly?.openLocationService.open(location: location)
            }
        }
        let initialVC = LocationsViewController(presenter: presenter, cardsFactory: LocationsViewsFactoryImpl(dependencies: presenter))
        self.topViewController = UINavigationController(rootViewController: initialVC)
        
        setAppearance()
    }
    
    private func setAppearance() {
        UINavigationBar.appearance().isTranslucent = true
    }
}

import UIKit
import WMF
import WMFComponents

/// The coordinator of one root tab. It builds the tab's root view controller and owns the tab's navigation controller.
@MainActor
protocol TabRootCoordinator: Coordinator {
    var tab: WMFAppTabType { get }

    /// Builds the view controller if the coordinator does not have one. Home and Saved hold it weakly, so read it again only after a navigation controller holds it.
    var rootViewController: UIViewController { get }

    func attach(navigationController: UINavigationController)
    func apply(theme: Theme)

    /// Called when the reader taps the tab that is already selected.
    func tabWasReselected()
}

extension TabRootCoordinator {
    func tabWasReselected() {}
}

/// Keeps the root tab coordinators. WMFAppViewController holds the only strong reference to this object.
/// Each tab coordinator holds its navigation controller strongly and never holds WMFAppViewController.
@MainActor
final class TabBarCoordinator {

    let home: HomeCoordinator
    let places: PlacesCoordinator
    let saved: SavedCoordinator
    let activity: ActivityTabCoordinator
    let search: SearchTabCoordinator

    /// In tab bar order: index `i` is the coordinator for `WMFAppTabType(rawValue: i)`.
    let rootCoordinators: [any TabRootCoordinator]

    init(theme: Theme, dataStore: MWKDataStore) {
        home = HomeCoordinator(theme: theme, dataStore: dataStore)
        places = PlacesCoordinator(theme: theme)
        saved = SavedCoordinator(theme: theme, dataStore: dataStore)
        activity = ActivityTabCoordinator(theme: theme, dataStore: dataStore)
        search = SearchTabCoordinator(theme: theme, dataStore: dataStore)
        rootCoordinators = [home, places, saved, activity, search]
        assert(rootCoordinators.map(\.tab.rawValue) == Array(rootCoordinators.indices))
    }

    /// Wraps each root view controller in its tab navigation controller and gives that navigation controller to its coordinator.
    func makeRootNavigationControllers(delegate: UINavigationControllerDelegate) -> [WMFComponentNavigationController] {
        rootCoordinators.map { coordinator in
            let navigationController = WMFComponentNavigationController(rootViewController: coordinator.rootViewController, modalPresentationStyle: .overFullScreen, customBarBackgroundColor: nil)
            navigationController.delegate = delegate
            coordinator.attach(navigationController: navigationController)
            return navigationController
        }
    }

    func apply(theme: Theme) {
        for coordinator in rootCoordinators {
            coordinator.apply(theme: theme)
        }
    }

    func coordinator(for tab: WMFAppTabType) -> any TabRootCoordinator {
        rootCoordinators[tab.rawValue]
    }
}

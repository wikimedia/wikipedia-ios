import UIKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFActivityTabCoordinator)
public final class ActivityTabCoordinator: NSObject, Coordinator {
    var theme: Theme
    let dataStore: MWKDataStore
    var navigationController: UINavigationController
    private weak var viewModel: WMFActivityTabViewModel?
    let dataController: WMFActivityTabDataController
    
    public init(theme: Theme, dataStore: MWKDataStore, navigationController: UINavigationController, viewModel: WMFActivityTabViewModel? = nil, dataController: WMFActivityTabDataController) {
        self.theme = theme
        self.dataStore = dataStore
        self.navigationController = navigationController
        self.viewModel = viewModel
        self.dataController = dataController
    }
    
    @discardableResult
    func start() -> Bool {

        // todo - use view controller
//
//        let activityTab = WMFActivityTabView(viewModel: viewModel)
//        let hostingController = UIHostingController(rootView: activityTab)
//        navigationController.present(hostingController, animated: true, completion: nil)
        return true
    }
}

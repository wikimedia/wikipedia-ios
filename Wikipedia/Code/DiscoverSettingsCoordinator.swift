import UIKit
import WMF
import WMFComponents
import WMFData

/// Owns the Discover settings screen and the screens under it: the source screen and, later,
/// the interests screen. Started from Settings and from Customize on the Discover reading list.
final class DiscoverSettingsCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        super.init()
    }

    // MARK: - Coordinator

    /// Reads the settings before the push, so the screen shows without a loading state.
    @discardableResult
    func start() -> Bool {
        Task { [weak self] in
            let viewModel = await WMFDiscoverSettingsViewModel.load()
            self?.showSettings(viewModel: viewModel)
        }
        return true
    }

    private func showSettings(viewModel: WMFDiscoverSettingsViewModel) {
        viewModel.didTapInterests = {
            // The interests screen lands with T440011.
        }

        let hostingController = WMFDiscoverSettingsHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }
}

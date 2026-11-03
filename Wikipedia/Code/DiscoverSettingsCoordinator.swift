import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

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
        viewModel.didTapSource = { [weak self] in
            self?.showSource()
        }
        viewModel.didTapInterests = {
            // The interests screen lands with T440011.
        }

        let hostingController = WMFDiscoverSettingsHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }

    // MARK: - Source

    private func showSource() {
        Task { [weak self] in
            let viewModel = await WMFDiscoverSetupViewModel.load(presentation: .settings)
            self?.showSource(viewModel: viewModel)
        }
    }

    private func showSource(viewModel: WMFDiscoverSetupViewModel) {
        viewModel.didChooseInterests = {
            // The interests screen lands with T440011.
        }
        viewModel.didChangeSource = { [weak self] previousSource, newSource in
            // The settings screen appears, and reads the settings, before the save is done.
            self?.settingsViewModel?.refresh()
            self?.showSourceChangedToast(previousSource: previousSource, newSource: newSource)
        }

        let hostingController = WMFDiscoverSetupHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }

    private var settingsViewModel: WMFDiscoverSettingsViewModel? {
        (navigationController.topViewController as? WMFDiscoverSettingsHostingController)?.viewModel
    }

    /// Undo puts the previous source back.
    private func showSourceChangedToast(previousSource: WMFDiscoverSource, newSource: WMFDiscoverSource) {
        let toastConfiguration = WMFToastConfig(
            title: Self.sourceChangedToastTitle(for: newSource),
            duration: 5,
            buttonTitle: CommonStrings.undo,
            buttonAction: { [weak self] in
                self?.restoreSource(previousSource)
            }
        )
        WMFToastPresenter.shared.show(toastConfiguration, in: navigationController.view.window)
    }

    private func restoreSource(_ source: WMFDiscoverSource) {
        let settingsViewModel = settingsViewModel
        Task {
            let dataController = WMFDiscoverReadingListDataController.shared
            var settings = await dataController.settings
            settings.source = source
            try? await dataController.saveSettings(settings)
            settingsViewModel?.refresh()
        }
    }

    // MARK: - Strings

    static func sourceChangedToastTitle(for source: WMFDiscoverSource) -> String {
        switch source {
        case .interests:
            return WMFLocalizedString("discover-settings-source-changed-toast-interests", value: "Your recommendations are now based on your interests.", comment: "Toast shown after the reader changes the source of the Discover reading list to their interests.")
        case .saved:
            return WMFLocalizedString("discover-settings-source-changed-toast-saved", value: "Your recommendations are now based on your saved articles.", comment: "Toast shown after the reader changes the source of the Discover reading list to their saved articles.")
        case .history:
            return WMFLocalizedString("discover-settings-source-changed-toast-history", value: "Your recommendations are now based on your reading history.", comment: "Toast shown after the reader changes the source of the Discover reading list to their reading history.")
        }
    }
}

import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Owns the Discover settings screen and the screens under it: the source screen and, later,
/// the interests screen. Started from Settings and from Customize on the Discover reading list.
final class DiscoverSettingsCoordinator: NSObject, Coordinator {

    enum Origin {
        case settings
        case discoverReadingList
    }

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private let origin: Origin

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, origin: Origin) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.origin = origin
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
        viewModel.didTurnOff = { [weak self] in
            self?.showTurnedOffToast()
        }

        let hostingController = WMFDiscoverSettingsHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }

    /// From Settings the reader already knows where to turn Discover back on, so the toast only shows from the Discover list.
    private func showTurnedOffToast() {
        guard origin == .discoverReadingList else { return }
        WMFToastPresenter.shared.show(WMFToastConfig(title: WMFDiscoverSettingsViewModel.turnedOffToastTitle, duration: 5))
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
            guard let self else { return }
            // The settings screen appears, and reads the settings, before the save is done.
            Self.refreshScreen(onTopOf: self.navigationController)
            self.showSourceChangedToast(previousSource: previousSource, newSource: newSource)
        }

        let hostingController = WMFDiscoverSetupHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }

    /// The screen on top reads the settings again. Undo on the toast can arrive on the settings
    /// screen or, after Back, on the Discover list.
    static func refreshScreen(onTopOf navigationController: UINavigationController) {
        switch navigationController.topViewController {
        case let settingsController as WMFDiscoverSettingsHostingController:
            settingsController.viewModel.refresh()
        case let listController as WMFDiscoverReadingListHostingController:
            listController.viewModel.reloadIfGenerationDue()
        default:
            break
        }
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
        let navigationController = navigationController
        Task {
            let dataController = WMFDiscoverReadingListDataController.shared
            var settings = await dataController.settings
            settings.source = source
            try? await dataController.saveSettings(settings)
            Self.refreshScreen(onTopOf: navigationController)
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

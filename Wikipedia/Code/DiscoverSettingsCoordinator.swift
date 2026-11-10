import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Owns the Discover settings screen and the screens under it: the source screen and the
/// interests screen. Started from Settings and from Customize on the Discover reading list.
final class DiscoverSettingsCoordinator: NSObject, Coordinator {

    enum Origin {
        case settings
        case discoverReadingList
    }

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private let origin: Origin
    private let readingListDataController: WMFDiscoverReadingListDataController
    private(set) var interestsCoordinator: DiscoverInterestsCoordinator?
    private var isShowingUndoToast = false

    init(
        navigationController: UINavigationController,
        dataStore: MWKDataStore,
        theme: Theme,
        origin: Origin,
        readingListDataController: WMFDiscoverReadingListDataController = .shared
    ) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.origin = origin
        self.readingListDataController = readingListDataController
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

    func showSettings(viewModel: WMFDiscoverSettingsViewModel) {
        viewModel.didTapSource = { [weak self] in
            self?.showSource()
        }
        viewModel.didTapInterests = { [weak self] in
            self?.showInterests()
        }
        viewModel.didLeave = { [readingListDataController] in
            Self.generateListIfDue(with: readingListDataController)
        }
        viewModel.didTurnOff = { [weak self] in
            self?.discoverDidTurnOff()
        }
        viewModel.didTurnOnWithoutInterests = { [weak self, weak viewModel] in
            self?.showInterests(didGoBack: { viewModel?.undoTurnOn() })
        }

        let hostingController = WMFDiscoverSettingsHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }

    /// From the Discover list, Discover off takes the list out from under the settings, so Back
    /// lands on the Saved tab, and the toast says where to turn Discover back on. From Settings
    /// the reader already knows where that is, and the stack stays as it is.
    func discoverDidTurnOff() {
        guard origin == .discoverReadingList else { return }
        removeDiscoverListUnderneath()
        WMFToastPresenter.shared.show(WMFToastConfig(title: WMFDiscoverSettingsViewModel.turnedOffToastTitle, duration: 5))
    }

    private func removeDiscoverListUnderneath() {
        var viewControllers = navigationController.viewControllers
        let listIndex = viewControllers.count - 2
        guard listIndex >= 0, viewControllers[listIndex] is WMFDiscoverReadingListHostingController else { return }
        viewControllers.remove(at: listIndex)
        navigationController.setViewControllers(viewControllers, animated: false)
    }

    // MARK: - Source

    private func showSource() {
        Task { [weak self] in
            let viewModel = await WMFDiscoverSetupViewModel.load(presentation: .settings)
            self?.showSource(viewModel: viewModel)
        }
    }

    /// Adjust to saved articles or reading history saves the source and ends the flow.
    func showSource(viewModel: WMFDiscoverSetupViewModel) {
        viewModel.didChooseInterests = { [weak self, weak viewModel] in
            self?.showInterests(didGoBack: { viewModel?.undoChooseInterests() })
        }
        viewModel.didChangeSource = { [weak self] previousSource, newSource in
            guard let self else { return }
            self.navigationController.popViewController(animated: true)
            Self.refreshScreen(onTopOf: self.navigationController, dataController: self.readingListDataController)
            self.showSourceChangedToast(previousSource: previousSource, newSource: newSource)
        }

        let hostingController = WMFDiscoverSetupHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
    }

    // MARK: - Interests

    /// Pushed from the Interests row, from Adjust to interests on the source screen, and when the
    /// switch goes on with interests as the source and no interest picked. The last two change
    /// the screen that pushes it before Done saves anything, so Back undoes that change.
    private func showInterests(didGoBack: (() -> Void)? = nil) {
        let coordinator = DiscoverInterestsCoordinator(navigationController: navigationController, dataStore: dataStore)
        coordinator.didFinish = { [weak self] in
            self?.leaveInterests()
        }
        coordinator.didGoBack = didGoBack
        interestsCoordinator = coordinator
        coordinator.start()
    }

    /// Done on the interests screen ends the flow, with the interests already committed. When the
    /// source screen is underneath it goes away too. Then interests are saved as the source. Back
    /// keeps the saved interests and the saved source.
    func leaveInterests() {
        let viewControllers = navigationController.viewControllers
        let sourceIndex = viewControllers.count - 2
        if sourceIndex >= 1, viewControllers[sourceIndex] is WMFDiscoverSetupHostingController {
            navigationController.popToViewController(viewControllers[sourceIndex - 1], animated: true)
        } else {
            navigationController.popViewController(animated: true)
        }
        commitSource(.interests)
    }

    /// Saves the settings with the source and refreshes the screen on top. A source that differs
    /// from the saved one shows the Undo toast.
    func commitSource(_ source: WMFDiscoverSource) {
        let navigationController = navigationController
        let dataController = readingListDataController
        Task { [weak self] in
            var settings = await dataController.settings
            let previousSource = settings.source
            guard previousSource != source else { return }
            settings.source = source
            try? await dataController.saveSettings(settings)
            Self.refreshScreen(onTopOf: navigationController, dataController: dataController)
            self?.showSourceChangedToast(previousSource: previousSource, newSource: source)
        }
    }

    /// The screen on top reads the settings again. Undo on the toast can arrive on the Discover
    /// settings screen, where Back makes the list later, or after Back: on the Discover list, or
    /// on Settings, where the list is made here when the saved source left it out of date.
    static func refreshScreen(onTopOf navigationController: UINavigationController, dataController: WMFDiscoverReadingListDataController) {
        switch navigationController.topViewController {
        case let settingsController as WMFDiscoverSettingsHostingController:
            settingsController.viewModel.refresh()
        case let listController as WMFDiscoverReadingListHostingController:
            listController.viewModel.reloadIfGenerationDue()
        default:
            generateListIfDue(with: dataController)
        }
    }

    /// Back on the Discover settings commits the changes made on it and under it, like on Android:
    /// a new source or article count makes the list again, once. The card on the Saved tab and the
    /// Discover list follow the run through the list state notification. A failed run keeps the
    /// current list, and the next visit to Saved tries again.
    static func generateListIfDue(with dataController: WMFDiscoverReadingListDataController) {
        Task {
            guard await dataController.settings.isEnabled else { return }
            _ = try? await dataController.generateRecommendationsIfNeeded()
        }
    }

    /// Undo puts the previous source back.
    private func showSourceChangedToast(previousSource: WMFDiscoverSource, newSource: WMFDiscoverSource) {
        let toastConfiguration = WMFToastConfig(
            title: Self.sourceChangedToastTitle(for: newSource),
            duration: 5,
            buttonTitle: CommonStrings.undo,
            buttonAction: { [weak self] in
                self?.saveSource(previousSource)
            }
        )
        isShowingUndoToast = true
        WMFToastPresenter.shared.show(toastConfiguration, in: navigationController.view.window) { [weak self] _ in
            self?.isShowingUndoToast = false
        }
    }

    /// Settings closing takes the Undo toast with it, also when a Discover screen is on top. The
    /// toast belongs to the Settings flow, and Undo over the Saved tab would change the list the
    /// reader is looking at.
    func settingsDidClose() {
        guard isShowingUndoToast else { return }
        WMFToastPresenter.shared.dismissCurrentToast()
    }

    /// Undo puts the previous source back. Interests stay as they are. The task keeps only the
    /// data controller and the navigation controller, so Undo works after this coordinator is gone.
    func saveSource(_ source: WMFDiscoverSource) {
        let navigationController = navigationController
        let dataController = readingListDataController
        Task {
            var settings = await dataController.settings
            settings.source = source
            try? await dataController.saveSettings(settings)
            Self.refreshScreen(onTopOf: navigationController, dataController: dataController)
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

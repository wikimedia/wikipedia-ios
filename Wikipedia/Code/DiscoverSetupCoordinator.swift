import UIKit
import WMF
import WMFComponents
import WMFData

/// Owns the Discover setup flow that starts from Get started on the Saved tab: the source
/// screen, then the interests screen or the first reading list.
final class DiscoverSetupCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private let readingListDataController: WMFDiscoverReadingListDataController
    private let discoverDataController: DiscoverAnnouncementDismissing
    private let interestsDataController: WMFDiscoverInterestsDataController

    private weak var setupViewController: WMFDiscoverSetupHostingController?
    private var interestsCoordinator: DiscoverInterestsCoordinator?
    private var readingListCoordinator: DiscoverReadingListCoordinator?

    init(
        navigationController: UINavigationController,
        dataStore: MWKDataStore,
        theme: Theme,
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        discoverDataController: DiscoverAnnouncementDismissing = WMFDiscoverDataController.shared,
        interestsDataController: WMFDiscoverInterestsDataController = .shared
    ) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.readingListDataController = readingListDataController
        self.discoverDataController = discoverDataController
        self.interestsDataController = interestsDataController
        super.init()
    }

    // MARK: - Coordinator

    /// Reads the available sources before the push, so the screen shows without a loading state.
    @discardableResult
    func start() -> Bool {
        Task { [weak self] in
            guard let self else { return }
            let viewModel = await WMFDiscoverSetupViewModel.load(readingListDataController: readingListDataController)
            showSetup(viewModel: viewModel)
        }
        return true
    }

    private func showSetup(viewModel: WMFDiscoverSetupViewModel) {
        viewModel.loggingDelegate = self
        viewModel.didChooseInterests = { [weak self] in
            self?.showInterests()
        }
        viewModel.didTurnOnDiscover = { [weak self] in
            self?.showReadingList()
        }

        let hostingController = WMFDiscoverSetupHostingController(viewModel: viewModel)
        setupViewController = hostingController
        navigationController.pushViewController(hostingController, animated: true)
    }

    // MARK: - Interests

    /// Back from the interests screen turns Discover on, with interests or with reading history
    /// from the alert, and the first list takes the place of the setup screens.
    private func showInterests() {
        let coordinator = DiscoverInterestsCoordinator(
            navigationController: navigationController,
            dataStore: dataStore,
            readingListDataController: readingListDataController,
            interestsDataController: interestsDataController
        )
        coordinator.didChooseSource = { [weak self] source in
            self?.turnOnDiscover(source: source)
        }
        interestsCoordinator = coordinator
        coordinator.start()
    }

    /// Saves the source, turns Discover on and opens the first list.
    func turnOnDiscover(source: WMFDiscoverSource) {
        Task { [weak self] in
            guard let self else { return }
            var settings = await readingListDataController.settings
            settings.source = source
            settings.isEnabled = true
            try? await readingListDataController.saveSettings(settings)
            try? discoverDataController.markAnnouncementDismissed()
            showReadingList()
        }
    }

    // MARK: - Reading list

    /// The list takes the place of the setup screens in the stack, so Back from the list returns
    /// to Saved. This matches Android, where the setup activity finishes when the list opens.
    private func showReadingList() {
        let coordinator = DiscoverReadingListCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme)
        readingListCoordinator = coordinator
        coordinator.start()

        guard let transitionCoordinator = navigationController.transitionCoordinator else {
            removeSetupScreens()
            return
        }
        transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.removeSetupScreens()
        }
    }

    private func removeSetupScreens() {
        let interestsViewController = interestsCoordinator?.interestsViewController
        var viewControllers = navigationController.viewControllers
        viewControllers.removeAll { $0 === setupViewController || $0 === interestsViewController }
        guard viewControllers.count != navigationController.viewControllers.count else { return }
        navigationController.setViewControllers(viewControllers, animated: false)
    }
}

// MARK: - DiscoverAnnouncementDismissing

/// The one call the coordinator makes on `WMFDiscoverDataController`, behind a protocol so tests can
/// stand in for it. `WMFDiscoverDataController` reads the live environment stores and has no
/// injectable initializer.
@MainActor
protocol DiscoverAnnouncementDismissing {
    func markAnnouncementDismissed() throws
}

extension WMFDiscoverDataController: DiscoverAnnouncementDismissing {}

// MARK: - WMFDiscoverSetupLoggingDelegate

extension DiscoverSetupCoordinator: WMFDiscoverSetupLoggingDelegate {
    // Instrumentation lands with T440585.
    func discoverSetupDidAppear() {}
    func discoverSetupDidTapContinue(source: WMFDiscoverSource) {}
}

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

    private weak var setupViewController: WMFDiscoverSetupHostingController?
    private var readingListCoordinator: DiscoverReadingListCoordinator?

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        super.init()
    }

    // MARK: - Coordinator

    /// Reads the available sources before the push, so the screen shows without a loading state.
    @discardableResult
    func start() -> Bool {
        Task { [weak self] in
            let viewModel = await WMFDiscoverSetupViewModel.load()
            self?.showSetup(viewModel: viewModel)
        }
        return true
    }

    private func showSetup(viewModel: WMFDiscoverSetupViewModel) {
        viewModel.loggingDelegate = self
        viewModel.didChooseInterests = {
            // The interests screen lands with T440011.
        }
        viewModel.didTurnOnDiscover = { [weak self] in
            self?.showReadingList()
        }

        let hostingController = WMFDiscoverSetupHostingController(viewModel: viewModel)
        setupViewController = hostingController
        navigationController.pushViewController(hostingController, animated: true)
    }

    // MARK: - Reading list

    /// The list takes the setup screen's place in the stack, so Back from the list returns to
    /// Saved. This matches Android, where the setup activity finishes when the list opens.
    private func showReadingList() {
        let coordinator = DiscoverReadingListCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme)
        readingListCoordinator = coordinator
        coordinator.start()

        guard let transitionCoordinator = navigationController.transitionCoordinator else {
            removeSetupScreen()
            return
        }
        transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.removeSetupScreen()
        }
    }

    private func removeSetupScreen() {
        guard let setupViewController else { return }
        var viewControllers = navigationController.viewControllers
        viewControllers.removeAll { $0 === setupViewController }
        navigationController.setViewControllers(viewControllers, animated: false)
    }
}

// MARK: - WMFDiscoverSetupLoggingDelegate

extension DiscoverSetupCoordinator: WMFDiscoverSetupLoggingDelegate {
    // Instrumentation lands with T440585.
    func discoverSetupDidAppear() {}
    func discoverSetupDidTapContinue(source: WMFDiscoverSource) {}
}

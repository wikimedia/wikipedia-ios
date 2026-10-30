import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

final class ReadingListsCoordinator: NSObject, Coordinator {

    private let navigationControllerProvider: () -> UINavigationController
    var navigationController: UINavigationController {
        navigationControllerProvider()
    }
    private let dataStore: MWKDataStore
    var theme: Theme
    private let filter: WMFReadingListsFilter
    private var dataSource: LegacyReadingListsDataSource?
    private var _viewModel: WMFReadingListsViewModel?
    private weak var hostingController: WMFReadingListsHostingController?
    private var createReadingListCoordinator: CreateReadingListCoordinator?

    convenience init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, filter: WMFReadingListsFilter = .all) {
        self.init(navigationControllerProvider: { navigationController }, dataStore: dataStore, theme: theme, filter: filter)
    }

    /// The Saved tab builds its segments before its navigation controller exists, so the
    /// navigation controller is resolved when first needed.
    init(navigationControllerProvider: @escaping () -> UINavigationController, dataStore: MWKDataStore, theme: Theme, filter: WMFReadingListsFilter = .all) {
        self.navigationControllerProvider = navigationControllerProvider
        self.dataStore = dataStore
        self.theme = theme
        self.filter = filter
        super.init()
    }

    // MARK: - Coordinator

    /// Pushes the segment as its own screen, as the "+N" tag on a saved article does.
    func start() -> Bool {
        navigationController.pushViewController(contentViewController, animated: true)
        return true
    }

    // MARK: - View model and embedded view controller

    var viewModel: WMFReadingListsViewModel {
        if let _viewModel {
            return _viewModel
        }

        let dataSource = LegacyReadingListsDataSource(dataStore: dataStore)
        let dataController = WMFLegacyReadingListsDataController(delegate: dataSource)
        self.dataSource = dataSource

        let viewModel = WMFReadingListsViewModel(dataController: dataController, filter: filter)
        viewModel.loggingDelegate = self

        viewModel.didTapReadingList = { [weak self] readingList in
            self?.showDetail(for: readingList)
        }

        viewModel.didTapCreateList = { [weak self] in
            self?.presentCreateReadingList()
        }

        viewModel.didPullToRefresh = { [weak self] in
            await self?.fullSync()
        }

        _viewModel = viewModel
        return viewModel
    }

    var contentViewController: WMFReadingListsHostingController {
        if let existingController = hostingController {
            return existingController
        }
        let controller = WMFReadingListsHostingController(viewModel: viewModel)
        hostingController = controller
        return controller
    }

    func reload() {
        _viewModel?.loadReadingLists()
    }

    // MARK: - Navigation

    private func showDetail(for readingList: WMFReadingList) {
        guard let list = dataSource?.readingList(withID: readingList.id) else {
            return
        }
        let detailViewController = ReadingListDetailViewController(for: list, with: dataStore)
        detailViewController.apply(theme: theme)
        navigationController.pushViewController(detailViewController, animated: true)
    }

    func presentCreateReadingList() {
        let coordinator = CreateReadingListCoordinator(presentingViewController: navigationController)
        coordinator.delegate = self
        coordinator.didDismiss = { [weak self] in
            self?.createReadingListCoordinator = nil
        }
        createReadingListCoordinator = coordinator
        coordinator.start()
    }

    private func fullSync() async {
        await withCheckedContinuation { continuation in
            dataStore.readingListsController.fullSync {
                continuation.resume()
            }
        }
    }

    private func handleReadingListError(_ error: Error) {
        if let readingListsError = error as? ReadingListError {
            WMFToastManager.sharedInstance.showToast(readingListsError.localizedDescription, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
        } else {
            WMFToastManager.sharedInstance.showToast(CommonStrings.unknownError, sticky: false, dismissPreviousToasts: true, tapCallBack: nil)
        }
    }
}

// MARK: - CreateReadingListCoordinatorDelegate

extension ReadingListsCoordinator: CreateReadingListCoordinatorDelegate {
    func createReadingListCoordinator(
        _ coordinator: CreateReadingListCoordinator,
        didCreateReadingListWith name: String,
        description: String,
        articles: [WMFArticle]
    ) {
        do {
            _ = try dataStore.readingListsController.createReadingList(named: name, description: description, with: articles)
            coordinator.dismiss(animated: true)
            ReadingListsFunnel.shared.logCreateInReadingLists()
            reload()
        } catch {
            switch error {
            case let readingListError as ReadingListError where readingListError == .listExistsWithTheSameName:
                coordinator.handleReadingListNameError(readingListError)
            default:
                coordinator.dismiss(animated: true) { [weak self] in
                    self?.handleReadingListError(error)
                }
                reload()
            }
        }
    }
}

// MARK: - WMFReadingListsLoggingDelegate

extension ReadingListsCoordinator: WMFReadingListsLoggingDelegate {
    func readingListsDidTapEdit() {
        ReadingListsFunnel.shared.logTappedEditButton()
    }

    func readingListsDidDelete(count: Int) {
        ReadingListsFunnel.shared.logDeleteInReadingLists(readingListsCount: count)
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.readingListDeletedAccessibilityNotification)
    }

    func readingListsDidFailToDelete(error: Error) {
        handleReadingListError(error)
    }
}

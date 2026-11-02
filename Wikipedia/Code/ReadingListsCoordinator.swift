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
    private var syncDidFinishObserver: NSObjectProtocol?

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
        // The list counts come from the database. A sync changes them after the screen loads.
        syncDidFinishObserver = NotificationCenter.default.addObserver(forName: ReadingListsController.syncDidFinishNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor in
                self?.reload()
            }
        }
    }

    deinit {
        if let syncDidFinishObserver {
            NotificationCenter.default.removeObserver(syncDidFinishObserver)
        }
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
        let createReadingListViewController = CreateReadingListViewController(theme: theme, articles: [])
        createReadingListViewController.delegate = self
        let navigationController = WMFComponentNavigationController(rootViewController: createReadingListViewController, modalPresentationStyle: .overFullScreen)
        self.navigationController.present(navigationController, animated: true)
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

// MARK: - CreateReadingListDelegate

extension ReadingListsCoordinator: CreateReadingListDelegate {
    func createReadingListViewController(_ createReadingListViewController: CreateReadingListViewController, didCreateReadingListWith name: String, description: String?, articles: [WMFArticle]) {
        do {
            _ = try dataStore.readingListsController.createReadingList(named: name, description: description, with: articles)
            createReadingListViewController.dismiss(animated: true)
            ReadingListsFunnel.shared.logCreateInReadingLists()
            reload()
        } catch {
            switch error {
            case let readingListError as ReadingListError where readingListError == .listExistsWithTheSameName:
                createReadingListViewController.handleReadingListNameError(readingListError)
            default:
                createReadingListViewController.dismiss(animated: true) { [weak self] in
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

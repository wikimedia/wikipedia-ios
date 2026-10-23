import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

final class ReadingListsCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    var theme: Theme
    private let filter: WMFReadingListsFilter
    private var dataSource: LegacyReadingListsDataSource?
    private weak var hostingController: WMFReadingListsHostingController?

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, filter: WMFReadingListsFilter = .all) {
        self.navigationController = navigationController
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

    // MARK: - Embedded view controller

    var contentViewController: WMFReadingListsHostingController {
        if let existingController = hostingController {
            return existingController
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

        let controller = WMFReadingListsHostingController(viewModel: viewModel)
        hostingController = controller
        return controller
    }

    func reload() {
        hostingController?.viewModel.loadReadingLists()
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

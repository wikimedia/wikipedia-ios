import UIKit
import WMF
import WMFComponents

protocol CreateReadingListCoordinatorDelegate: AnyObject {
    func createReadingListCoordinator(
        _ coordinator: CreateReadingListCoordinator,
        didCreateReadingListWith name: String,
        description: String,
        articles: [WMFArticle]
    )
}

/// Presents the "Create a new list" form. It owns the modal navigation controller the form shows in.
///
/// With `encodedPageIDs`, the form imports a shared reading list: it fetches the articles first, then
/// fills the name in. The delegate saves the list and calls back with the result.
@MainActor
final class CreateReadingListCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    weak var delegate: CreateReadingListCoordinatorDelegate?
    /// Called once the form leaves the screen, by any path. Owners release the coordinator here.
    var didDismiss: (() -> Void)?

    let moveFromReadingList: ReadingList?
    private(set) var articles: [WMFArticle]

    private weak var presentingViewController: UIViewController?
    private let viewModel: WMFCreateReadingListViewModel
    private let importer: ReadingListImporter?
    private var importTask: Task<Void, Never>?

    var isInImportingMode: Bool {
        importer != nil
    }

    init(presentingViewController: UIViewController, articles: [WMFArticle] = [], moveFromReadingList: ReadingList? = nil, encodedPageIDs: String? = nil, dataStore: MWKDataStore? = nil) {
        self.presentingViewController = presentingViewController
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList

        if let encodedPageIDs {
            importer = ReadingListImporter(encodedPageIDs: encodedPageIDs, dataStore: dataStore)
            viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)
        } else {
            importer = nil
            viewModel = WMFCreateReadingListViewModel(mode: .create)
        }

        let hostingController = WMFCreateReadingListHostingController(viewModel: viewModel)
        navigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .pageSheet)
        navigationController.sheetPresentationController?.prefersGrabberVisible = true
        super.init()

        viewModel.didTapCreate = { [weak self] name, description in
            guard let self else { return }
            delegate?.createReadingListCoordinator(self, didCreateReadingListWith: name, description: description, articles: self.articles)
        }
        viewModel.didTapClose = { [weak self] in
            self?.close()
        }
        viewModel.didDismiss = { [weak self] in
            self?.didDismiss?()
        }
    }

    deinit {
        importTask?.cancel()
    }

    // MARK: - Coordinator

    @discardableResult
    func start() -> Bool {
        guard let presentingViewController else {
            return false
        }
        presentingViewController.present(navigationController, animated: true)
        startImportIfNeeded()
        return true
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Delegate callbacks

    func handleReadingListNameError(_ error: ReadingListError) {
        viewModel.showNameError(error.localizedDescription)
    }

    /// Disables the Create button while the delegate saves the list.
    func setCreating(_ isCreating: Bool) {
        viewModel.isCreating = isCreating
    }

    // MARK: - Private

    private func close() {
        if isInImportingMode {
            ReadingListsFunnel.shared.logCancelImport()
        }
        dismiss(animated: true)
    }

    private func startImportIfNeeded() {
        guard let importer else { return }
        importTask = Task { [weak self] in
            do {
                let importedArticles = try await importer.importArticles()
                guard let self else { return }
                articles = importedArticles
                viewModel.importDidSucceed()
            } catch {
                guard let self else { return }
                viewModel.importDidFail()
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
            }
        }
    }
}

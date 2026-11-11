import UIKit
import WMF
import WMFComponents
import WMFData

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
/// shows them, all selected, and fills the name in. With `discoverPages`, the form shows the Discover
/// articles, all selected. In both cases, the form sends only the selected articles to the delegate. The delegate saves the list and calls back with the result.
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
    private let discoverPages: [WMFDiscoverRecommendedPage]
    private let dataStore: MWKDataStore?
    private var importTask: Task<Void, Never>?

    var isInImportingMode: Bool {
        importer != nil
    }

    init(
        presentingViewController: UIViewController,
        articles: [WMFArticle] = [],
        moveFromReadingList: ReadingList? = nil,
        encodedPageIDs: String? = nil,
        discoverPages: [WMFDiscoverRecommendedPage] = [],
        dataStore: MWKDataStore? = nil
    ) {
        self.presentingViewController = presentingViewController
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        self.discoverPages = discoverPages
        self.dataStore = dataStore

        if let encodedPageIDs {
            importer = ReadingListImporter(encodedPageIDs: encodedPageIDs, dataStore: dataStore)
            viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)
        } else if !discoverPages.isEmpty {
            importer = nil
            viewModel = WMFCreateReadingListViewModel(
                mode: .saveDiscoverList(date: Date()),
                articles: discoverPages.map(Self.selectableArticle(for:)),
                validateName: Self.nameValidation(dataStore: dataStore)
            )
        } else {
            importer = nil
            viewModel = WMFCreateReadingListViewModel(mode: .create, articles: articles.compactMap(Self.selectableArticle(for:)))
        }

        let hostingController = WMFCreateReadingListHostingController(viewModel: viewModel)
        navigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .formSheet)
        navigationController.sheetPresentationController?.prefersGrabberVisible = true
        super.init()
        navigationController.presentationController?.delegate = self

        viewModel.didTapCreate = { [weak self] name, description in
            guard let self else { return }
            let selectedIDs = self.viewModel.selectedArticleIDs
            let selectedArticles: [WMFArticle]
            if !self.discoverPages.isEmpty {
                DiscoverInstrumentation.shared.logSaveSheetSaveTap()
                selectedArticles = Self.selectedArticles(of: self.discoverPages, selectedIDs: selectedIDs, dataStore: self.dataStore)
            } else {
                selectedArticles = Self.selectedArticles(of: self.articles, selectedIDs: selectedIDs)
            }
            delegate?.createReadingListCoordinator(self, didCreateReadingListWith: name, description: description, articles: selectedArticles)
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
        if !discoverPages.isEmpty {
            DiscoverInstrumentation.shared.logSaveSheetImpression(itemCount: discoverPages.count)
        }
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
        logCancelImportIfNeeded()
        logDiscoverCancelIfNeeded()
        dismiss(animated: true)
    }

    private func logDiscoverCancelIfNeeded() {
        if !discoverPages.isEmpty {
            DiscoverInstrumentation.shared.logSaveSheetCancelTap()
        }
    }

    private func logCancelImportIfNeeded() {
        if isInImportingMode {
            ReadingListsFunnel.shared.logCancelImport()
        }
    }

    /// Fetches or creates the saved article objects of the selected Discover pages, in list order.
    static func selectedArticles(of pages: [WMFDiscoverRecommendedPage], selectedIDs: [String], dataStore: MWKDataStore?) -> [WMFArticle] {
        guard let dataStore else { return [] }
        let selectedIDSet = Set(selectedIDs)
        return pages
            .filter { selectedIDSet.contains($0.id) }
            .compactMap { page in
                guard let articleURL = page.articleURL else { return nil }
                return dataStore.fetchOrCreateArticle(with: articleURL)
            }
    }

    static func selectedArticles(of articles: [WMFArticle], selectedIDs: [String]) -> [WMFArticle] {
        let selectedIDSet = Set(selectedIDs)
        return articles.filter { article in
            guard let key = article.key else { return false }
            return selectedIDSet.contains(key)
        }
    }

    static func selectableArticle(for article: WMFArticle) -> WMFCreateReadingListViewModel.Article? {
        guard let key = article.key,
              let languageCode = article.url?.wmf_languageCode else {
            return nil
        }
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: article.variant))
        return WMFCreateReadingListViewModel.Article(
            id: key,
            displayTitle: article.displayTitleHTML,
            project: project,
            description: article.capitalizedWikidataDescriptionOrSnippet,
            thumbnailURL: article.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth())
        )
    }

    private static func selectableArticle(for page: WMFDiscoverRecommendedPage) -> WMFCreateReadingListViewModel.Article {
        WMFCreateReadingListViewModel.Article(
            id: page.id,
            displayTitle: page.displayTitle,
            project: page.project,
            description: page.description,
            thumbnailURL: page.thumbnailURL
        )
    }

    /// Disables Create while a list with the same name exists.
    static func nameValidation(dataStore: MWKDataStore?) -> (String) -> String? {
        return { [weak dataStore] name in
            guard let dataStore,
                  (try? dataStore.readingListsController.listExists(with: name, in: dataStore.viewContext)) == true else {
                return nil
            }
            return ReadingListError.listExistsWithTheSameName.localizedDescription
        }
    }

    private func startImportIfNeeded() {
        guard let importer else { return }
        importTask = Task { [weak self] in
            do {
                let importedArticles = try await importer.importArticles()
                guard let self else { return }
                articles = importedArticles
                viewModel.importDidSucceed(articles: importedArticles.compactMap(Self.selectableArticle(for:)))
            } catch {
                guard let self else { return }
                viewModel.importDidFail()
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension CreateReadingListCoordinator: UIAdaptivePresentationControllerDelegate {
    /// A swipe down closes the form like the close button does.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        logCancelImportIfNeeded()
        logDiscoverCancelIfNeeded()
    }
}

import UIKit
import WMFComponents
import WMFData

final class AllArticlesCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private var dataController: WMFLegacySavedArticlesDataController?
    private weak var hostingController: WMFAllArticlesHostingController?

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        super.init()
    }

    // MARK: - Coordinator

    func start() -> Bool {
        // No-op for embedded use case - use contentViewController instead
        return true
    }

    // MARK: - Embedded View Controller

    var contentViewController: WMFAllArticlesHostingController {
        if let existingController = hostingController {
            return existingController
        }

        let dataController = WMFLegacySavedArticlesDataController(delegate: self)
        self.dataController = dataController

        let localizedStrings = WMFAllArticlesViewModel.LocalizedStrings(
            title: CommonStrings.savedTitle,
            emptyStateTitle: WMFLocalizedString("saved-empty-title", value: "No saved pages yet", comment: "Title for empty saved articles state"),
            emptyStateMessage: WMFLocalizedString("saved-empty-message", value: "Save pages to view them later, even offline", comment: "Message for empty saved articles state"),
            searchPlaceholder: WMFLocalizedString("saved-search-placeholder", value: "Search saved articles", comment: "Placeholder for saved articles search"),
            cancel: CommonStrings.cancelActionTitle,
            addToList: WMFLocalizedString("saved-add-to-list", value: "Add to list", comment: "Add to reading list button"),
            unsave: WMFLocalizedString("saved-unsave", value: "Unsave", comment: "Unsave button"),
            share: CommonStrings.shareActionTitle,
            delete: CommonStrings.deleteActionTitle
        )

        let viewModel = WMFAllArticlesViewModel(
            dataController: dataController,
            localizedStrings: localizedStrings
        )

        viewModel.didTapArticle = { [weak self] article in
            self?.showArticle(title: article.title, project: article.project)
        }

        viewModel.didTapShare = { [weak self] article in
            self?.shareArticle(article)
        }

        viewModel.didTapAddToList = { [weak self] articles in
            self?.showAddToListSheet(for: articles)
        }

        let controller = WMFAllArticlesHostingController(viewModel: viewModel)
        self.hostingController = controller
        return controller
    }

    // MARK: - Navigation

    private func showArticle(title: String, project: WMFProject) {

        guard let siteURL = project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .undefined
        )
        articleCoordinator.start()
    }

    private func shareArticle(_ article: WMFSavedArticle) {
        guard let siteURL = article.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: article.title) else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [articleURL], applicationActivities: nil)
        navigationController.present(activityVC, animated: true)
    }

    private func showAddToListSheet(for articles: [WMFSavedArticle]) {
        // Present reading list selection UI
    }
}

// MARK: - WMFLegacySavedArticlesDataControllerDelegate

extension AllArticlesCoordinator: WMFLegacySavedArticlesDataControllerDelegate {
    func fetchAllSavedArticles() -> [WMFSavedArticle] {
        let fetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "list.isDefault == YES AND isDeletedLocally == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

        do {
            let entries = try dataStore.viewContext.fetch(fetchRequest)
            return entries.compactMap { entry -> WMFSavedArticle? in
                guard let inMemoryKey = entry.inMemoryKey,
                      let url = inMemoryKey.url,
                      let title = url.wmf_title,
                      let siteURL = url.wmf_site,
                      let languageCode = siteURL.wmf_languageCode else {
                    return nil
                }

                let languageVariantCode = inMemoryKey.languageVariantCode
                
                let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))

                return WMFSavedArticle(
                    id: entry.objectID.uriRepresentation().absoluteString,
                    title: title,
                    project: project,
                    savedDate: entry.createdDate as Date?,
                    readingListNames: entry.list?.name.map { [$0] } ?? [],
                )
            }
        } catch {
            return []
        }
    }
        
    func deleteSavedArticle(with id: String) async throws {
        guard let url = URL(string: id),
              let objectID = dataStore.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
              let entry = try? dataStore.viewContext.existingObject(with: objectID) as? ReadingListEntry,
              let articleKey = entry.articleKey,
              let article = dataStore.fetchArticle(withKey: articleKey) else {
            return
        }
        
        dataStore.readingListsController.unsave([article], in: dataStore.viewContext)
    }
        
    func addArticleToReadingList(articleID: String, listName: String) async throws {
        // Implementation for adding to a specific reading list
    }
}

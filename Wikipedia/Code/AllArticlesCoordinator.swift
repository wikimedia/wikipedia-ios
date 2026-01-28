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
        
        NotificationCenter.default.addObserver(self, selector: #selector(articleDidChange(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
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
            emptyStateTitle: CommonStrings.allArticlesEmptySavedTitle,
            emptyStateMessage: CommonStrings.allArticlesEmptySavedSubtitle,
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
    
    // MARK: - Private
    
    // MARK: - Article changes
    
    @objc func articleDidChange(_ note: Notification) {
        guard
            let article = note.object as? WMFArticle,
            article.hasChangedValuesForCurrentEventThatAffectSavedArticlePreviews,
            let articleKey = article.inMemoryKey
            else {
                return
        }
        
        print("🤔article did change: \(article.isDownloaded)")
        
        // fetch entry with the same key
        let databaseKey = articleKey.databaseKey
        let fetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "articleKey == %@", databaseKey)
        do {
            guard let readingListEntry = try dataStore.viewContext.fetch(fetchRequest).first,
                  let list = readingListEntry.list else {
                return
            }
            let id = readingListEntry.objectID.uriRepresentation().absoluteString
            let alertType = determineAlertType(for: readingListEntry, article: article, readingList: list, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
            
            hostingController?.viewModel.updateAlertType(id: id, alertType: alertType)
            
        } catch {
            // nothing
        }
    }
    
    private func determineAlertType(
        for entry: ReadingListEntry,
        article: WMFArticle,
        readingList: ReadingList,
        listLimit: Int,
        entryLimit: Int
    ) -> WMFSavedArticleAlertType {
        var alertType: WMFSavedArticleAlertType = .none

        // 1. Check entry-level API errors
        if let entryError = entry.APIError {
            switch entryError {
            case .entryLimit:
                if readingList.isDefault {
                    alertType = .genericNotSynced
                } else {
                    alertType = .entryLimitExceeded(limit: entryLimit)
                }
            default:
                break
            }
        }

        // 2. Check list-level API errors
        if let listError = readingList.APIError {
            switch listError {
            case .listLimit:
                alertType = .listLimitExceeded(limit: listLimit)
            default:
                break
            }
        }

        // 3. Check article download state (only if no sync errors)
        switch alertType {
        case .none, .downloading, .articleError:
            if article.error != .none {
                return .articleError(article.error.localizedDescription)
            } else if !article.isDownloaded {
                return .downloading
            }
        default:
            break
        }

        return alertType
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
                
                // Fetch the article for alert determination
                let article = dataStore.fetchArticle(withKey: inMemoryKey.databaseKey, variant: inMemoryKey.languageVariantCode)

                // Determine alert type
                let alertType: WMFSavedArticleAlertType
                if let article = article,
                   let list = entry.list {
                    alertType = determineAlertType(
                        for: entry,
                        article: article,
                        readingList: list,
                        listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser,
                        entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue
                    )
                } else {
                    alertType = .none
                }

                let languageVariantCode = inMemoryKey.languageVariantCode
                
                let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))

                return WMFSavedArticle(
                    id: entry.objectID.uriRepresentation().absoluteString,
                    title: title,
                    project: project,
                    savedDate: entry.createdDate as Date?,
                    readingListNames: entry.list?.name.map { [$0] } ?? [],
                    alertType: alertType
                )
            }
        } catch {
            return []
        }
    }
        
    func deleteSavedArticle(with id: String) {
        guard let url = URL(string: id),
              let objectID = dataStore.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
              let entry = try? dataStore.viewContext.existingObject(with: objectID) as? ReadingListEntry,
              let articleKey = entry.articleKey,
              let article = dataStore.fetchArticle(withKey: articleKey) else {
            return
        }
        
        dataStore.readingListsController.unsave([article], in: dataStore.viewContext)
    }
        
    func addArticleToReadingList(articleID: String, listName: String) {
        // Implementation for adding to a specific reading list
    }
}

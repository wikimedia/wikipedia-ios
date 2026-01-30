import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift

final class AllArticlesCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private var dataController: WMFLegacySavedArticlesDataController?
    private weak var hostingController: WMFAllArticlesHostingController?
    var sortType: SortActionType = .byRecentlyAdded
    
    var exitEditingModeAction: (() -> Void)?

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
            emptyStateTitle: CommonStrings.allArticlesEmptySavedTitle,
            emptyStateMessage: CommonStrings.allArticlesEmptySavedSubtitle,
            addToList: CommonStrings.addToReadingListShortActionTitle,
            unsave: CommonStrings.shortUnsaveTitle,
            open: CommonStrings.articleTabsOpen,
            openInNewTab: CommonStrings.articleTabsOpenInNewTab,
            openInBackgroundTab: CommonStrings.articleTabsOpenInBackgroundTab,
            removeFromSaved: CommonStrings.unsaveTitle,
            share: CommonStrings.shortShareTitle,
            listLimitExceeded: CommonStrings.readingListsErrorListLimitExceeded,
            entryLimitExceeded: CommonStrings.readingListsErrorArticleLimitExceeded,
            notSynced: CommonStrings.readingListsErrorNotSynced,
            articleQueuedToBeDownloaded: CommonStrings.readingListsWarningArticleQueuedToBeDownloaded)

        let viewModel = WMFAllArticlesViewModel(
            dataController: dataController,
            localizedStrings: localizedStrings
        )

        viewModel.didTapArticle = { [weak self] article in
            self?.showArticle(title: article.title, project: article.project, inNewTab: false)
        }
        
        viewModel.didTapOpenInNewTab = { [weak self] article in
            self?.showArticle(title: article.title, project: article.project, inNewTab: true)
        }
        
        viewModel.didTapOpenInBackgroundTab = { [weak self] article in
            self?.openArticleInBackgroundTab(title: article.title, project: article.project)
        }

        viewModel.didTapShare = { [weak self] article, cgRect in
            self?.shareArticle(article, cgRect: cgRect)
        }

        viewModel.didTapAddToList = { [weak self] articles in
            self?.showAddToListSheet(for: articles)
        }
        
        viewModel.didUpdateEditingMode = { [weak self] isEditing in
            if !isEditing {
                self?.exitEditingModeAction?()
            }
        }
        
        viewModel.didPullToRefresh = { [weak self] in
            guard let self else { return }
            
            await self.fullSync()
            await self.retryFailedArticleDownloads()
            
            await MainActor.run {
                self.hostingController?.viewModel.loadArticles()
            }
        }
        
        viewModel.didTapArticleAlert = { [weak self] savedArticle in
            guard let self,
                  let article = self.wmfArticlesFromSavedArticles([savedArticle]).first else {
                return
            }
            presentArticleErrorRecovery(with: article)
        }

        let controller = WMFAllArticlesHostingController(viewModel: viewModel)
        self.hostingController = controller
        return controller
    }

    // MARK: - Navigation

    private func showArticle(title: String, project: WMFProject, inNewTab: Bool) {

        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        articleURL.wmf_languageVariantCode = project.languageVariantCode
        
        let tabConfig: ArticleTabConfig = inNewTab ? .appendArticleAndAssignNewTabAndSetToCurrent : .appendArticleAndAssignCurrentTab
        
        if inNewTab {
            WMFArticleTabsDataController.shared.didTapOpenNewTab()
            ArticleTabsFunnel.shared.logLongPressOpenInNewTab()
        }
        
        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .undefined,
            tabConfig: tabConfig
        )
        articleCoordinator.start()
    }
    
    private func openArticleInBackgroundTab(title: String, project: WMFProject) {

        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        
        articleURL.wmf_languageVariantCode = project.languageVariantCode
        
        Task {
            do {
                let articleTabsDataController = WMFArticleTabsDataController.shared
                articleTabsDataController.didTapOpenNewTab()
                
                let tabsCount = try await articleTabsDataController.tabsCount()
                let tabsMax = articleTabsDataController.tabsMax
                let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: project, articleURL: articleURL)
                if tabsCount >= tabsMax {
                    
                    if let currentTabIdentifier = try await articleTabsDataController.currentTabIdentifier() {
                        _ = try await articleTabsDataController.appendArticle(article, toTabIdentifier: currentTabIdentifier)
                    } else {
                        _ = try await articleTabsDataController.createArticleTab(initialArticle: article)
                    }
                    
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        WMFAlertManager.sharedInstance.showBottomWarningAlertWithMessage(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil,  buttonTitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousAlerts: true)
                    }
                } else {
                    _ = try await articleTabsDataController.createArticleTab(initialArticle: article, setAsCurrent: false)
                    ArticleTabsFunnel.shared.logLongPressOpenInBackgroundTab()
                }
                
            } catch {
                DDLogError("Failed to create background tab: \(error)")
            }
        }
        
    }

    private func shareArticle(_ savedArticle: WMFSavedArticle, cgRect: CGRect) {
        
        guard let article = wmfArticlesFromSavedArticles([savedArticle]).first else {
            return
        }
        
        var customActivities: [UIActivity] = []
        let addToReadingListActivity = AddToReadingListActivity { [weak self] in
            guard let self else { return }
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
            addArticlesToReadingListViewController.delegate = self
            let navVC = WMFComponentNavigationController(rootViewController: addArticlesToReadingListViewController, modalPresentationStyle: .overFullScreen)
            navigationController.present(navVC, animated: true, completion: nil)
        }
        customActivities.append(addToReadingListActivity)
        
        let shareActivityController = ShareActivityController(article: article, customActivities: customActivities)
        if UIDevice.current.userInterfaceIdiom == .pad {
            shareActivityController.popoverPresentationController?.sourceView = navigationController.view
            shareActivityController.popoverPresentationController?.sourceRect = cgRect
        }
        navigationController.present(shareActivityController, animated: true, completion: nil)
        
    }
    
    private func wmfArticlesFromSavedArticles(_ savedArticles: [WMFSavedArticle]) -> [WMFArticle] {
        let articleURLs: [URL] = savedArticles.compactMap { savedArticle in
            guard let siteURL = savedArticle.project.siteURL,
                  var articleURL = siteURL.wmf_URL(withTitle: savedArticle.title) else {
                return nil
            }
            
            articleURL.wmf_languageVariantCode = savedArticle.project.languageVariantCode
            return articleURL
        }
        
        let inMemoryKeys = articleURLs.compactMap { WMFInMemoryURLKey(url: $0)}
        
        guard let articles = try? dataStore.viewContext.fetchArticlesWithInMemoryURLKeys(inMemoryKeys) else {
            return []
        }
        
        return articles
    }

    private func showAddToListSheet(for savedArticles: [WMFSavedArticle]) {
        
        let articles = wmfArticlesFromSavedArticles(savedArticles)
        
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: addArticlesToReadingListViewController, modalPresentationStyle: .overFullScreen)
        addArticlesToReadingListViewController.delegate = self
        self.navigationController.present(navVC, animated: true)
    }
    
    private func retryFailedArticleDownloads(_ completion: @escaping () -> Void) {
        dataStore.performBackgroundCoreDataOperation { (moc) in
            defer {
                completion()
            }
            let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
            request.predicate = NSPredicate(format: "isDeletedLocally == NO")
            request.propertiesToFetch = ["articleKey"]
            do {
                let entries = try moc.fetch(request)
                let keys = entries.compactMap { $0.articleKey }
                guard !keys.isEmpty else {
                    return
                }
                try moc.retryFailedArticleDownloads(with: keys)
            } catch let error {
                DDLogError("Error retrying failed articles: \(error)")
            }
        }
    }
    
    private func presentArticleErrorRecovery(with article: WMFArticle) {
        switch article.error {
        case .apiFailed:
            let alert = UIAlertController(title: article.error.localizedDescription, message: nil, preferredStyle: .actionSheet)
            let retry = UIAlertAction(title: CommonStrings.retryActionTitle, style: .default) { _ in
                article.retryDownload()
            }
            alert.addAction(retry)
            let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .default)
            alert.addAction(cancel)
            navigationController.present(alert, animated: true)
        default:
            break
        }
    }
    
    // MARK: - Article changes
    
    @objc func articleDidChange(_ note: Notification) {
        guard
            let article = note.object as? WMFArticle,
            article.hasChangedValuesForCurrentEventThatAffectSavedArticlePreviews,
            let articleKey = article.inMemoryKey
            else {
                return
        }

        // fetch entry with the same key
        let databaseKey = articleKey.databaseKey
        let fetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "articleKey == %@", databaseKey)
        do {
            guard let readingListEntry = try dataStore.viewContext.fetch(fetchRequest).first,
                  let list = readingListEntry.list else {
                return
            }
            
            guard let titleAndProject = readingListEntry.titleAndProject() else {
                return
            }
            let title = titleAndProject.title
            let project = titleAndProject.project
            
            let alertType = determineAlertType(for: readingListEntry, article: article, readingList: list, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
            
            let identifier = identifier(for: title, project: project)
            hostingController?.viewModel.updateAlertType(id: identifier, alertType: alertType)
            
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
    
    private func fullSync() async {
        await withCheckedContinuation { continuation in
            dataStore.readingListsController.fullSync {
                continuation.resume()
            }
        }
    }

    private func retryFailedArticleDownloads() async {
        await withCheckedContinuation { continuation in
            retryFailedArticleDownloads {
                continuation.resume()
            }
        }
    }
    
    private func identifier(for title: String, project: WMFProject) -> String {
        return "\(project.id)|\(title)"
    }
}

// MARK: - WMFLegacySavedArticlesDataControllerDelegate

extension AllArticlesCoordinator: WMFLegacySavedArticlesDataControllerDelegate {
    func fetchAllSavedArticles() -> [WMFSavedArticle] {
        let fetchRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDeletedLocally == NO")

        do {
            let entries = try dataStore.viewContext.fetch(fetchRequest)
            
            var articlesDict: [String: WMFSavedArticle] = [:]
            
            for entry in entries {
                
                guard let inMemoryKey = entry.inMemoryKey,
                      let titleAndProject = entry.titleAndProject() else {
                    continue
                }
                
                let title = titleAndProject.title
                let project = titleAndProject.project
                let id = identifier(for: title, project: project)
                
                if var existingArticle = articlesDict[id] {
                    // Merge reading list name
                    if let listName = entry.list?.name, !existingArticle.readingListNames.contains(listName) {
                        existingArticle.readingListNames.append(listName)
                        articlesDict[id] = existingArticle
                    }
                } else {
                    // Fetch the article for alert determination
                    let article = dataStore.fetchArticle(withKey: inMemoryKey.databaseKey, variant: inMemoryKey.languageVariantCode)

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

                    let identifier = identifier(for: title, project: project)
                    let savedArticle = WMFSavedArticle(
                        id: identifier,
                        title: title,
                        project: project,
                        savedDate: entry.createdDate as Date?,
                        readingListNames: entry.list?.name.map { [$0] } ?? [],
                        alertType: alertType
                    )
                    articlesDict[id] = savedArticle
                }
            }
            
            // Return sorted
            switch sortType {
            case .byRecentlyAdded:
                return articlesDict.values.sorted { ($0.savedDate ?? Date()) > ($1.savedDate ?? Date()) }
            case .byTitle:
                return articlesDict.values.sorted { $0.title < $1.title }
            }
            
        } catch {
            return []
        }
    }
        
    func deleteSavedArticle(withProject project: WMFProject, title: String) {
        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title),
              let articleKey = articleURL.wmf_inMemoryKey?.databaseKey,
              let article = dataStore.fetchArticle(withKey: articleKey) else {
            return
        }
        
        articleURL.wmf_languageVariantCode = project.languageVariantCode
        
        dataStore.readingListsController.unsave([article], in: dataStore.viewContext)
    }
}

private extension ReadingListEntry {
    func titleAndProject() -> (title: String, project: WMFProject)? {
        guard let inMemoryKey = inMemoryKey,
              let url = inMemoryKey.url,
              let title = url.wmf_title,
              let siteURL = url.wmf_site,
              let languageCode = siteURL.wmf_languageCode else {
            return nil
        }
        
        let languageVariantCode = inMemoryKey.languageVariantCode
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        return (title, project)
    }
}

extension AllArticlesCoordinator: AddArticlesToReadingListDelegate {
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // no-op
    }
    
    func addArticlesToReadingListDidDisappear(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // no-op
    }
    
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: WMF.ReadingList) {
        hostingController?.viewModel.toggleEditing()
        exitEditingModeAction?()
        hostingController?.viewModel.loadArticles()
    }
}

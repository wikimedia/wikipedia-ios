import Foundation
import CoreData
import WMFData
import CocoaLumberjackSwift

/// Serves `WMFLegacyReadingListsDataController` from the legacy Core Data store.
///
/// Reads run on a background context and return plain models. Writes go through
/// `ReadingListsController` on the main thread, as every legacy screen does.
public final class LegacyReadingListsDataSource: WMFLegacyReadingListsDataControllerDelegate {

    public typealias UnsaveConfirmation = (_ articles: [WMFSavedArticle], _ fromLongPress: Bool, _ completion: @escaping (Bool) -> Void) -> Void

    private let dataStore: MWKDataStore

    /// Transitional: the Saved tab coordinator shows the "remove from lists?" alert and unsaves on confirmation.
    public var unsaveConfirmation: UnsaveConfirmation?

    public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }

    // MARK: - Reads

    public func fetchSavedArticles() async throws -> [WMFSavedArticle] {
        try await dataStore.performBackgroundCoreDataOperationAsync { moc in
            let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
            request.predicate = NSPredicate(format: "isDeletedLocally == NO")
            let entries = try moc.fetch(request)
            return Self.savedArticles(from: entries, in: moc, restrictedToListID: nil)
        }
    }

    public func fetchArticles(inReadingList readingListID: String) async throws -> [WMFSavedArticle] {
        try await dataStore.performBackgroundCoreDataOperationAsync { moc in
            guard let list = Self.readingList(withID: readingListID, in: moc) else {
                return []
            }
            let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
            request.predicate = NSPredicate(format: "list == %@ && isDeletedLocally == NO", list)
            let entries = try moc.fetch(request)
            return Self.savedArticles(from: entries, in: moc, restrictedToListID: list.objectID)
        }
    }

    public func fetchReadingLists() async throws -> [WMFReadingList] {
        try await dataStore.performBackgroundCoreDataOperationAsync { moc in
            let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
            request.predicate = NSPredicate(format: "isDeletedLocally == NO")
            request.relationshipKeyPathsForPrefetching = ["previewArticles", "entries"]
            let listLimit = moc.wmf_readingListsConfigMaxListsPerUser
            let entryLimit = moc.wmf_readingListsConfigMaxEntriesPerList.intValue
            return try moc.fetch(request).map { Self.readingList($0, listLimit: listLimit, entryLimit: entryLimit) }
        }
    }

    public func defaultReadingListID() async throws -> String? {
        await MainActor.run {
            dataStore.viewContext.defaultReadingList?.objectID.uriRepresentation().absoluteString
        }
    }

    public func isDefaultReadingListEnabled() async -> Bool {
        await MainActor.run {
            dataStore.readingListsController.isDefaultListEnabled
        }
    }

    public func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder? {
        await MainActor.run {
            guard let list = Self.readingList(withID: readingListID, in: dataStore.viewContext),
                  let rawValue = list.sortOrder?.intValue else {
                return nil
            }
            return WMFReadingListSortOrder(rawValue: rawValue)
        }
    }

    public func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws {
        try await MainActor.run {
            let moc = dataStore.viewContext
            guard let list = Self.readingList(withID: readingListID, in: moc) else {
                return
            }
            list.sortOrder = NSNumber(value: sortOrder.rawValue)
            if moc.hasChanges {
                try moc.save()
            }
        }
    }

    // MARK: - Writes

    public func createReadingList(name: String, description: String?) async throws -> WMFReadingList {
        try await MainActor.run {
            let moc = dataStore.viewContext
            let list = try dataStore.readingListsController.createReadingList(named: name, description: description)
            return Self.readingList(list, listLimit: moc.wmf_readingListsConfigMaxListsPerUser, entryLimit: moc.wmf_readingListsConfigMaxEntriesPerList.intValue)
        }
    }

    public func updateReadingList(id readingListID: String, name: String?, description: String?) async throws {
        await MainActor.run {
            guard let list = Self.readingList(withID: readingListID, in: dataStore.viewContext) else {
                return
            }
            dataStore.readingListsController.updateReadingList(list, with: name, newDescription: description)
        }
    }

    public func deleteReadingLists(ids readingListIDs: [String]) async throws {
        try await MainActor.run {
            let moc = dataStore.viewContext
            let lists = readingListIDs.compactMap { Self.readingList(withID: $0, in: moc) }
            guard !lists.isEmpty else {
                return
            }
            try dataStore.readingListsController.delete(readingLists: lists)
        }
    }

    public func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws {
        try await MainActor.run {
            let moc = dataStore.viewContext
            guard let list = Self.readingList(withID: readingListID, in: moc) else {
                return
            }
            let articles = self.articles(withIDs: articleIDs)
            try dataStore.readingListsController.add(articles: articles, to: list)
        }
    }

    public func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws {
        try await MainActor.run {
            let moc = dataStore.viewContext
            guard let list = Self.readingList(withID: readingListID, in: moc) else {
                return
            }
            let articles = self.articles(withIDs: articleIDs)
            try dataStore.readingListsController.remove(articles: articles, readingList: list)
        }
    }

    public func unsaveArticles(ids articleIDs: [String]) async throws {
        await MainActor.run {
            let articles = self.articles(withIDs: articleIDs)
            dataStore.readingListsController.unsave(articles, in: dataStore.viewContext)
        }
    }

    public func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) {
        guard let unsaveConfirmation else {
            Task {
                try? await unsaveArticles(ids: articles.map { $0.id })
                await MainActor.run { completion(true) }
            }
            return
        }
        unsaveConfirmation(articles, fromLongPress, completion)
    }

    // MARK: - Mapping

    /// Builds `WMFSavedArticle.id` for a title and project. The same string is the key everywhere.
    public static func articleID(title: String, project: WMFProject) -> String {
        "\(project.id)|\(title)"
    }

    /// The articles behind a list of ids, on the view context.
    public func articles(withIDs articleIDs: [String]) -> [WMFArticle] {
        articleIDs.compactMap { articleID in
            guard let url = Self.articleURL(fromID: articleID) else {
                return nil
            }
            return dataStore.fetchArticle(with: url)
        }
    }

    public static func articleURL(fromID articleID: String) -> URL? {
        guard let separator = articleID.firstIndex(of: "|") else {
            return nil
        }
        let projectID = String(articleID[..<separator])
        let title = String(articleID[articleID.index(after: separator)...])
        guard let project = WMFProject(id: projectID), let siteURL = project.siteURL,
              var url = siteURL.wmf_URL(withTitle: title) else {
            return nil
        }
        url.wmf_languageVariantCode = project.languageVariantCode
        return url
    }

    private static func readingList(withID readingListID: String, in moc: NSManagedObjectContext) -> ReadingList? {
        guard let url = URL(string: readingListID),
              let coordinator = moc.persistentStoreCoordinator,
              let objectID = coordinator.managedObjectID(forURIRepresentation: url) else {
            return nil
        }
        return try? moc.existingObject(with: objectID) as? ReadingList
    }

    private static func readingList(_ list: ReadingList, listLimit: Int, entryLimit: Int) -> WMFReadingList {
        let liveEntries = (list.entries ?? []).filter { !$0.isDeletedLocally }
        let articleIDs = Set(liveEntries.compactMap { entry -> String? in
            guard let titleAndProject = entry.titleAndProject() else { return nil }
            return articleID(title: titleAndProject.title, project: titleAndProject.project)
        })
        let previewArticles = (list.previewArticles?.array as? [WMFArticle]) ?? []
        let previewThumbnailURLs = previewArticles.prefix(4).compactMap { $0.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth()) }

        let alertType: WMFReadingListAlertType
        switch list.APIError {
        case .listLimit:
            alertType = .listLimitExceeded(limit: listLimit)
        case .entryLimit:
            alertType = .entryLimitExceeded(limit: entryLimit)
        default:
            alertType = .none
        }

        return WMFReadingList(
            id: list.objectID.uriRepresentation().absoluteString,
            name: list.name ?? "",
            description: list.readingListDescription,
            isDefault: list.isDefault,
            createdDate: list.createdDate as Date?,
            articleCount: Int(list.countOfEntries),
            articleIDs: articleIDs,
            previewThumbnailURLs: previewThumbnailURLs,
            alertType: alertType,
            sortOrder: list.sortOrder.flatMap { WMFReadingListSortOrder(rawValue: $0.intValue) }
        )
    }

    /// One `WMFSavedArticle` per article. An article in several lists appears once, with every
    /// custom list name. The saved date is the default list entry's date, or the newest entry's.
    private static func savedArticles(from entries: [ReadingListEntry], in moc: NSManagedObjectContext, restrictedToListID: NSManagedObjectID?) -> [WMFSavedArticle] {
        let listLimit = moc.wmf_readingListsConfigMaxListsPerUser
        let entryLimit = moc.wmf_readingListsConfigMaxEntriesPerList.intValue
        var articlesByID: [String: WMFSavedArticle] = [:]
        var order: [String] = []

        for entry in entries {
            guard let inMemoryKey = entry.inMemoryKey, let titleAndProject = entry.titleAndProject() else {
                continue
            }
            let id = articleID(title: titleAndProject.title, project: titleAndProject.project)
            let isDefaultEntry = entry.list?.isDefault ?? false
            let customListName = isDefaultEntry ? nil : entry.list?.name

            if var existing = articlesByID[id] {
                if let customListName, !existing.readingListNames.contains(customListName) {
                    existing.readingListNames.append(customListName)
                }
                articlesByID[id] = existing
                continue
            }

            let article = fetchArticle(inContext: moc, databaseKey: inMemoryKey.databaseKey)
            let alertType: WMFSavedArticleAlertType
            if let article, let list = entry.list {
                alertType = determineAlertType(for: entry, article: article, readingList: list, listLimit: listLimit, entryLimit: entryLimit)
            } else {
                alertType = .none
            }

            let savedDate = (article?.savedDate) ?? (entry.createdDate as Date?)
            let savedArticle = WMFSavedArticle(
                id: id,
                title: titleAndProject.title,
                displayTitle: article?.displayTitle,
                project: titleAndProject.project,
                savedDate: restrictedToListID == nil ? savedDate : (entry.createdDate as Date?) ?? savedDate,
                description: article?.capitalizedWikidataDescriptionOrSnippet,
                snippet: article?.snippet,
                thumbnailURL: article?.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth()),
                readingListNames: restrictedToListID == nil ? (customListName.map { [$0] } ?? []) : (article?.sortedNonDefaultReadingLists.compactMap { $0.name } ?? []),
                alertType: alertType
            )
            articlesByID[id] = savedArticle
            order.append(id)
        }

        return order.compactMap { articlesByID[$0] }
    }

    private static func fetchArticle(inContext moc: NSManagedObjectContext, databaseKey: String) -> WMFArticle? {
        let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", databaseKey)
        request.fetchLimit = 1
        return try? moc.fetch(request).first
    }

    /// Sync errors win over download state. A download error only matters while the article is not downloaded.
    public static func determineAlertType(for entry: ReadingListEntry, article: WMFArticle, readingList: ReadingList, listLimit: Int, entryLimit: Int) -> WMFSavedArticleAlertType {
        var alertType: WMFSavedArticleAlertType = .none

        if let entryError = entry.APIError, entryError == .entryLimit {
            alertType = readingList.isDefault ? .genericNotSynced : .entryLimitExceeded(limit: entryLimit)
        }

        if let listError = readingList.APIError, listError == .listLimit {
            alertType = .listLimitExceeded(limit: listLimit)
        }

        switch alertType {
        case .none, .downloading, .articleError:
            if article.isDownloaded {
                return .none
            } else if article.error != .none {
                return .articleError(article.error.localizedDescription)
            } else {
                return .downloading
            }
        default:
            return alertType
        }
    }
}

public extension ReadingListEntry {
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

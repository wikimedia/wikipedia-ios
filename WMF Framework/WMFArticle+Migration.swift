import Foundation
import CoreData
import WMFData
import CocoaLumberjackSwift

@objc public final class WMFArticleSavedStateMigrationManager: NSObject {

    @objc public static let shared = WMFArticleSavedStateMigrationManager()
    let dataStore = MWKDataStore.shared()

    override private init() {
        super.init()
    }

    // MARK: - Public API

    public func migrateAllIfNeeded() async {
        await runMigration(limit: 500)
    }

    public func migrateIncremental() async {
        await runMigration(limit: 20)
    }

    @objc public func removeFromSaved(forArticleObjectID objectID: NSManagedObjectID) {
        unsave(forArticleObjectID: objectID)
    }

    public func clearAll() {
        clearAllSavedData()
    }

    @objc public func migrateIncrementalObjC() {
        Task { await migrateIncremental() }
    }

    // rethink name
    public func migrateNewlySyncedArticles(withURLs urls: [URL]) {
        migrateSyncedArticles(withURLs: urls)
    }


    // MARK: - Migration

    private func runMigration(limit: Int?) async {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("Missing WMFData store")
            return
        }

        do {
            try await dataStore.performBackgroundCoreDataOperationAsync { wikipediaContext in
                wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
                    DDLogError("Could not create WMFData background context")
                    return
                }
                wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                request.predicate = NSPredicate(
                    format: "savedDate != NULL AND (isSavedMigrated == NO OR isSavedMigrated == nil)"
                )
                request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
                if let limit { request.fetchLimit = limit }

                let articles = try wikipediaContext.fetch(request)
                guard !articles.isEmpty else { return }

                var snapshots: [SavedArticleSnapshot] = []
                snapshots.reserveCapacity(articles.count)

                for article in articles {
                    guard
                        let savedDate = article.savedDate,
                        let ids = self.getIdFromLegacyArticleURL(article)
                    else { continue }

                    snapshots.append(
                        SavedArticleSnapshot(
                            ids: ids,
                            savedDate: savedDate,
                            viewedDate: article.viewedDate
                        )
                    )
                }

                guard !snapshots.isEmpty else { return }

                try await wmfContext.perform {
                    for snap in snapshots {
                        try self.applySavedStateOnWMFContext(snapshot: snap, in: wmfContext, wmfDataStore: wmfDataStore)
                    }
                    if wmfContext.hasChanges { try wmfContext.save() }
                }

                for article in articles {
                    article.isSavedMigrated = true
                }
                if wikipediaContext.hasChanges { try wikipediaContext.save() }
            }

        } catch {
            DDLogError("WMFArticle migration error: \(error)")
        }
    }

    @objc public func migrateSyncedArticles(withURLs urls: [URL]) {
        guard !urls.isEmpty else { return }
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("[SavedPagesMirror] Missing WMFData store")
            return
        }

        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.migrateSyncedArticles(withURLs: urls)
            }
            return
        }

        dataStore.performBackgroundCoreDataOperation { wikipediaContext in
            wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            var snaps: [SavedArticleSnapshot] = []
            snaps.reserveCapacity(urls.count)

            for url in urls {
                autoreleasepool {
                    guard let ids = self.pageIDs(from: url) else {
                        DDLogWarn("[Mirror] Skipping URL (cannot derive PageIDs): \(url.absoluteString)")
                        return
                    }

                    let article: WMFArticle? = self.dataStore.fetchArticle(with: url, in: wikipediaContext)
                    let savedDate: Date = {
                        if let sd = article?.savedDate { return sd }
                        if let entryDate = self.getSavedDateFromReadingLists(for: url, in: wikipediaContext) {
                            return entryDate
                        }
                        DDLogInfo("[Mirror] Using fallback savedDate for \(url.absoluteString)")
                        return Date()
                    }()

                    let viewedDate = article?.viewedDate

                    snaps.append(
                        SavedArticleSnapshot(
                            ids: ids,
                            savedDate: savedDate,
                            viewedDate: viewedDate
                        )
                    )
                }
            }

            guard !snaps.isEmpty else { return }

            guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
                DDLogError("[SavedPagesMirror] Could not create WMFData background context")
                return
            }
            wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            wmfContext.performAndWait {
                do {
                    for snap in snaps {
                        try self.applySavedStateOnWMFContext(snapshot: snap,
                                                             in: wmfContext,
                                                             wmfDataStore: wmfDataStore)
                    }
                    if wmfContext.hasChanges { try wmfContext.save() }
                } catch {
                    DDLogError("[SavedPagesMirror] Failed mirroring to WMFData: \(error)")
                }
            }
        }
    }

    // MARK: - Update Saved State

    @objc func unsave(forArticleObjectID objectID: NSManagedObjectID) {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else { return }

        // Value-only data to carry across contexts
        var ids: PageIDs?
        var viewedDate: Date?
        var legacyError: Error?

        let group = DispatchGroup()
        group.enter()

        dataStore.performBackgroundCoreDataOperation { wikipediaContext in
            wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            do {
                guard let article = try wikipediaContext.existingObject(with: objectID) as? WMFArticle else {
                    DDLogError("Unsave failed: article not found for objectID \(objectID)")
                    group.leave()
                    return
                }

                ids = self.getIdFromLegacyArticleURL(article)
                viewedDate = article.viewedDate

            } catch {
                legacyError = error
            }

            group.leave()
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            if let err = legacyError {
                DDLogError("Unsave (legacy) failed for objectID \(objectID): \(err)")
                return
            }
            guard let ids else {
                DDLogError("Unsave aborted: missing PageIDs for objectID \(objectID)")
                return
            }

            guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
                DDLogError("[SavedPagesMigration] WMF background context unavailable")
                return
            }
            wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            wmfContext.perform {
                do {
                    try self.syncSavedState(
                        fromArticleWith: ids,
                        viewedDate: viewedDate,
                        to: wmfContext,
                        action: .unsave,
                        wmfDataStore: wmfDataStore
                    )
                    if wmfContext.hasChanges {
                        try wmfContext.save()
                    }
                } catch {
                    DDLogError("[SavedPagesMigration] WMF unsave apply failed: \(error)")
                }
            }
        }
    }

    private func syncSavedState(fromArticleWith ids: PageIDs,
                                viewedDate: Date?,
                                to wmfDataContext: NSManagedObjectContext,
                                action: SavedSyncAction,
                                wmfDataStore: WMFCoreDataStore) throws {

        let projectID = ids.projectID
        let namespaceID = ids.namespaceID
        let title = ids.title

        let predicate = NSPredicate(
            format: "projectID == %@ AND namespaceID == %d AND title == %@",
            projectID, namespaceID, title
        )

        switch action {
        case .save(let date):
            let snap = SavedArticleSnapshot(ids: ids, savedDate: date, viewedDate: viewedDate)
            try applySavedStateOnWMFContext(snapshot: snap, in: wmfDataContext, wmfDataStore: wmfDataStore)

        case .unsave:
            guard let pages: [CDPage] = try wmfDataStore.fetch(
                entityType: CDPage.self,
                predicate: predicate,
                fetchLimit: 1,
                in: wmfDataContext
            ), let page = pages.first else {
                DDLogError("[SavedPagesMigration] Unsave: no CDPage for PID \(projectID) nsID \(namespaceID) title \(title)")
                return
            }

            if let saved = page.savedInfo {
                wmfDataContext.delete(saved)
                page.savedInfo = nil
            } else {
                DDLogInfo("[SavedPagesMigration] Unsave no-op: savedInfo already nil for title \(title)")
            }

            if page.timestamp == nil {
                DDLogInfo("[SavedPagesMigration] Deleting CDPage for \(title) — timestamp nil after unsave")
            }
        }
    }

    private func applySavedStateOnWMFContext(snapshot: SavedArticleSnapshot, in wmfContext: NSManagedObjectContext, wmfDataStore: WMFCoreDataStore) throws {
        let projectID = snapshot.ids.projectID
        let namespaceID = snapshot.ids.namespaceID
        let title = snapshot.ids.title

        let predicate = NSPredicate(
            format: "projectID == %@ AND namespaceID == %d AND title == %@",
            projectID, namespaceID, title
        )

        guard let page = try wmfDataStore.fetchOrCreate(entityType: CDPage.self,
                                                        predicate: predicate,
                                                        in: wmfContext) else {
            DDLogError("[SavedPagesMigration] save: no CDPage for PID \(projectID) nsID \(namespaceID) title \(title)")
            return
        }

        page.title = title
        page.namespaceID = namespaceID
        page.projectID = projectID
        page.timestamp = snapshot.viewedDate ?? snapshot.savedDate

        if let existing = page.savedInfo {
            existing.savedDate = snapshot.savedDate
        } else {
            let saved = CDPageSavedInfo(context: wmfContext)
            saved.savedDate = snapshot.savedDate
            page.savedInfo = saved
        }
    }

    // MARK: - Delete all

    @objc func clearAllSavedData() {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("[SavedPagesMigration] Missing WMFData store")
            return
        }

        guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
            DDLogError("[SavedPagesMigration] Could not create WMFData background context")
            return
        }
        wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        wmfContext.perform {
            do {
                let savedInfoFR = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageSavedInfo")
                let deleteSavedInfo = NSBatchDeleteRequest(fetchRequest: savedInfoFR)
                deleteSavedInfo.resultType = .resultTypeObjectIDs

                if let result = try wmfContext.execute(deleteSavedInfo) as? NSBatchDeleteResult,
                   let deletedIDs = result.result as? [NSManagedObjectID],
                   !deletedIDs.isEmpty {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                        into: [wmfContext, (try? wmfDataStore.viewContext)].compactMap { $0 }
                    )
                }
            } catch {
                DDLogError("[SavedPagesMigration] Batch clear in WMFData failed: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private enum SavedSyncAction {
        case save(date: Date)
        case unsave
    }

    private struct PageIDs {
        let projectID: String
        let namespaceID: Int16
        let title: String
    }

    private struct SavedArticleSnapshot {
        let ids: PageIDs
        let savedDate: Date
        let viewedDate: Date?
    }

    private func pageIDs(from articleURL: URL) -> PageIDs? {
        guard
            let siteURL = articleURL.wmf_site,
            let project = WikimediaProject(siteURL: siteURL),
            let wmfProject = project.wmfProject
        else { return nil }

        let title = (articleURL.wmf_title ?? "").normalizedForCoreData
        let namespaceID = Int16(articleURL.namespace?.rawValue ?? 0)
        return PageIDs(projectID: wmfProject.id, namespaceID: namespaceID, title: title)
    }

    private func getIdFromLegacyArticleURL(_ article: WMFArticle) -> PageIDs? {
        guard
            let url = article.url,
            let siteURL = url.wmf_site,
            let project = WikimediaProject(siteURL: siteURL),
            let wmfProject = project.wmfProject
        else { return nil }

        let title = (url.wmf_title ?? "").normalizedForCoreData
        let namespaceID = Int16(url.namespace?.rawValue ?? 0)
        let projectID = wmfProject.id

        return PageIDs(projectID: projectID, namespaceID: namespaceID, title: title)
    }

    private func getSavedDateFromReadingLists(for url: URL, in moc: NSManagedObjectContext) -> Date? {
        guard let key = url.wmf_inMemoryKey?.databaseKey ?? url.wmf_inMemoryKey?.databaseKey else {
            return nil
        }

        let req: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        req.predicate = NSPredicate(format: "articleKey == %@ AND isDeletedLocally == NO", key)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: true)]
        req.fetchLimit = 1

        do {
            let entries = try moc.fetch(req)
            return entries.first?.createdDate as Date?
        } catch {
            DDLogError("[Mirror] ReadingListEntry fetch failed for key=\(key): \(error)")
            return nil
        }
    }
}

// MARK: - Private extensions

private extension MWKDataStore {
    func performBackgroundCoreDataOperationAsync<T>(_ block: @escaping (NSManagedObjectContext) async throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            // Background ops should start on the main thread
            Task { @MainActor in
                self.performBackgroundCoreDataOperation { context in
                    Task {
                        do {
                            let value = try await block(context)
                            continuation.resume(returning: value)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
}


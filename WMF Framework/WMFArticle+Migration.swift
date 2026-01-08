import Foundation
import CoreData
@preconcurrency import WMFData
import CocoaLumberjackSwift

@objc public final class WMFArticleSavedStateMigrationManager: NSObject, @unchecked Sendable {

    @objc public static let shared = WMFArticleSavedStateMigrationManager()
    let dataStore = MWKDataStore.shared()
    
    // Serial queue to prevent concurrent operations
    private let serialQueue = DispatchQueue(label: "org.wikimedia.savedstate.migration", qos: .utility)


    override private init() {
        super.init()
    }

    // MARK: - Public API

    public func migrateAllIfNeeded() async {
        guard shouldRunMigration() else { return }
        
        await withCheckedContinuation { continuation in
            serialQueue.async {
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    await self.runMigration(limit: 500)
                    semaphore.signal()
                }
                semaphore.wait()
                continuation.resume()
            }
        }
    }

    public func migrateIncremental() async {
        guard shouldRunMigration() else { return }
        
        await withCheckedContinuation { continuation in
            serialQueue.async {
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    await self.runMigration(limit: 20)
                    semaphore.signal()
                }
                semaphore.wait()
                continuation.resume()
            }
        }
    }

    @objc(removeFromSavedWithURLs:)
    public func removeFromSaved(withUrls urls: [URL]) {
        guard shouldRunMigration() else { return }

        serialQueue.async {
            self.unsave(urls: urls)
            
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                do {
                    try await self.resetMigrationFlagForLegacyArticles(with: urls)
                } catch {
                    DDLogError("[SavedPagesMigration] Reset migration flag failed: \(error)")
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    public func clearAll() {
        guard shouldRunMigration() else { return }
        
        serialQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await self.clearAllSavedData()
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    @objc public func migrateIncrementalObjC() {
        guard shouldRunMigration() else { return }
        
        serialQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await self.runMigration(limit: 20)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    public func migrateNewlySyncedArticles(withURLs urls: [URL]) {
        guard shouldRunMigration() else { return }
        
        serialQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await self.migrateSyncedArticles(withURLs: urls)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    public func shouldRunMigration() -> Bool {
        let should = WMFActivityTabDataController.activityAssignmentForObjC() == .activityTab
        return should
    }

    // MARK: - Migration

    private func runMigration(limit: Int?) async {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("Missing WMFData store")
            return
        }

        let snapshots: [SavedArticleSnapshot]
        do {
            snapshots = try await dataStore.performBackgroundCoreDataOperationAsync { wikipediaContext in
                wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                request.predicate = NSPredicate(
                    format: "savedDate != NULL AND (isSavedMigrated == NO OR isSavedMigrated == nil)"
                )
                request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
                if let limit { request.fetchLimit = limit }

                let articles = try wikipediaContext.fetch(request)
                guard !articles.isEmpty else { return [] }

                var localSnaps: [SavedArticleSnapshot] = []
                localSnaps.reserveCapacity(articles.count)

                for article in articles {
                    autoreleasepool {
                        guard let savedDate = article.savedDate,
                              let url = article.url,
                              let ids = Self.getPageIDs(from: url)
                        else { return }
                        
                        localSnaps.append(
                            SavedArticleSnapshot(
                                ids: ids,
                                savedDate: savedDate,
                                viewedDate: article.viewedDate
                            )
                        )
                        article.isSavedMigrated = true
                    }
                }

                if wikipediaContext.hasChanges {
                    try wikipediaContext.save()
                }

                return localSnaps
            }
        } catch {
            DDLogError("WMFArticle migration error (legacy read/save): \(error)")
            return
        }

        guard !snapshots.isEmpty else { return }

        guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
            DDLogError("Could not create WMFData background context")
            return
        }
        wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            try await wmfContext.perform {
                for snap in snapshots {
                    autoreleasepool {
                        do {
                            try Self.applySavedStateOnWMFContext(
                                snapshot: snap,
                                in: wmfContext,
                                wmfDataStore: wmfDataStore
                            )
                        } catch {
                            DDLogError("[SavedPagesMigration] Failed to apply saved state: \(error)")
                        }
                    }
                }
                if wmfContext.hasChanges { try wmfContext.save() }
            }
        } catch {
            DDLogError("WMFData saved-article migration error: \(error)")
        }
    }

    private func migrateSyncedArticles(withURLs urls: [URL]) async {
        let dedupedURLs = Array(Set(urls))
        
        guard !dedupedURLs.isEmpty else { return }
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("[SavedPagesMirror] Missing WMFData store")
            return
        }

        let snapshots: [SavedArticleSnapshot]
        do {
            snapshots = try await self.dataStore.performBackgroundCoreDataOperationAsync { (wikipediaContext: NSManagedObjectContext) -> [SavedArticleSnapshot] in
                wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                var localSnaps: [SavedArticleSnapshot] = []
                localSnaps.reserveCapacity(dedupedURLs.count)

                for url in dedupedURLs {
                    autoreleasepool {
                        guard let ids = Self.getPageIDs(from: url) else {
                            DDLogWarn("[Mirror] Skipping URL (cannot derive PageIDs): \(url.absoluteString)")
                            return
                        }

                        let article = self.dataStore.fetchArticle(with: url, in: wikipediaContext)
                        let savedDate: Date = {
                            if let sd = article?.savedDate { return sd }
                            if let entryDate = Self.getSavedDateFromReadingLists(for: url, in: wikipediaContext) {
                                return entryDate
                            }
                            DDLogInfo("[Mirror] Using fallback savedDate for \(url.absoluteString)")
                            return Date()
                        }()

                        let viewedDate = article?.viewedDate

                        localSnaps.append(
                            SavedArticleSnapshot(
                                ids: ids,
                                savedDate: savedDate,
                                viewedDate: viewedDate
                            )
                        )

                        if let article, article.isSavedMigrated == false {
                            article.isSavedMigrated = true
                        }
                    }
                }

                if wikipediaContext.hasChanges {
                    try wikipediaContext.save()
                }

                return localSnaps
            }
        } catch {
            DDLogError("[SavedPagesMirror] Legacy snapshot build failed: \(error)")
            return
        }

        guard !snapshots.isEmpty else { return }

        guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
            DDLogError("[SavedPagesMirror] Could not create WMFData background context")
            return
        }
        wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            try await wmfContext.perform {
                for snap in snapshots {
                    try Self.applySavedStateOnWMFContext(
                        snapshot: snap,
                        in: wmfContext,
                        wmfDataStore: wmfDataStore
                    )
                }
                if wmfContext.hasChanges { try wmfContext.save() }
            }
        } catch {
            DDLogError("[SavedPagesMirror] Failed mirroring to WMFData: \(error)")
        }
    }

    // MARK: - Private

    private func unsave(urls: [URL]) {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else { return }
        guard !urls.isEmpty else { return }

        guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
            DDLogError("[SavedPagesMigration] WMF background context unavailable")
            return
        }
        wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        wmfContext.performAndWait {
            for url in urls {
                autoreleasepool {
                    guard let ids = Self.getPageIDs(from: url) else {
                        DDLogError("[SavedPagesMigration] Unsave aborted: could not derive PageIDs from URL \(url.absoluteString)")
                        return
                    }

                    do {
                        try Self.unsaveInWMFData(pageIDs: ids, in: wmfContext, store: wmfDataStore)
                    } catch {
                        DDLogError("[SavedPagesMigration] WMF unsave (URL) failed: \(error)")
                    }
                }
            }
            
            if wmfContext.hasChanges {
                do {
                    try wmfContext.save()
                } catch {
                    DDLogError("[SavedPagesMigration] Failed to save unsave changes: \(error)")
                }
            }
        }
    }

    // MARK: - WMFData static writers

    private static func unsaveInWMFData(pageIDs: PageIDs, in wmfContext: NSManagedObjectContext, store wmfDataStore: WMFCoreDataStore) throws {
        let predicate = makePredicate(for: pageIDs)

        guard let pages: [CDPage] = try wmfDataStore.fetch(
            entityType: CDPage.self,
            predicate: predicate,
            fetchLimit: 1,
            in: wmfContext
        ), let page = pages.first else {
            DDLogError("[SavedPagesMigration] Unsave: no CDPage for PID \(pageIDs.projectID) nsID \(pageIDs.namespaceID) title \(pageIDs.title)")
            return
        }

        if let saved = page.savedInfo {
            wmfContext.delete(saved)
            page.savedInfo = nil
        } else {
            DDLogInfo("[SavedPagesMigration] Unsave no-op: savedInfo already nil for title \(pageIDs.title)")
        }

        if page.timestamp == nil {
            DDLogInfo("[SavedPagesMigration] Deleting CDPage for \(pageIDs.title) — timestamp nil after unsave")
        }
        print("😅unsaveInWMFData - end")
    }

    private static func applySavedStateOnWMFContext(snapshot: SavedArticleSnapshot, in wmfContext: NSManagedObjectContext, wmfDataStore: WMFCoreDataStore) throws {
        let predicate = makePredicate(for: snapshot.ids)

        guard let page = try wmfDataStore.fetchOrCreate(entityType: CDPage.self,
                                                        predicate: predicate,
                                                        in: wmfContext) else {
            DDLogError("[SavedPagesMigration] save: no CDPage for PID \(snapshot.ids.projectID) nsID \(snapshot.ids.namespaceID) title \(snapshot.ids.title)")
            return
        }

        page.title = snapshot.ids.title
        page.namespaceID = snapshot.ids.namespaceID
        page.projectID = snapshot.ids.projectID
        page.timestamp = snapshot.viewedDate ?? snapshot.savedDate

        if let existing = page.savedInfo {
            existing.savedDate = snapshot.savedDate
        } else {
            let saved = CDPageSavedInfo(context: wmfContext)
            saved.savedDate = snapshot.savedDate
            page.savedInfo = saved
        }
    }

    private static func makePredicate(for ids: PageIDs) -> NSPredicate {
        let predicate = NSPredicate(format: "projectID == %@ AND namespaceID == %d AND title == %@",
                    ids.projectID, ids.namespaceID, ids.title)
        return predicate
    }

    // MARK: - Delete all

    private func clearAllSavedData() async {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("[SavedPagesMigration] Missing WMFData store")
            return
        }

        guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
            DDLogError("[SavedPagesMigration] Could not create WMFData background context")
            return
        }
        wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        await wmfContext.perform {
            do {
                let pagesFR: NSFetchRequest<CDPage> = CDPage.fetchRequest()
                pagesFR.predicate = NSPredicate(format: "savedInfo != nil")
                pagesFR.fetchBatchSize = 500

                let pagesWithSavedInfo = try wmfContext.fetch(pagesFR)

                if !pagesWithSavedInfo.isEmpty {
                    for page in pagesWithSavedInfo {
                        page.savedInfo = nil
                    }

                    if wmfContext.hasChanges {
                        try wmfContext.save()
                    }
                }

                let savedInfoFR = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageSavedInfo")
                let deleteSavedInfo = NSBatchDeleteRequest(fetchRequest: savedInfoFR)
                deleteSavedInfo.resultType = .resultTypeObjectIDs

                if let result = try wmfContext.execute(deleteSavedInfo) as? NSBatchDeleteResult,
                   let deletedIDs = result.result as? [NSManagedObjectID],
                   !deletedIDs.isEmpty {

                    let viewContext = try? wmfDataStore.viewContext

                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                        into: [viewContext].compactMap { $0 }
                    )
                }
            } catch {
                DDLogError("[SavedPagesMigration] Batch clear in WMFData failed: \(error)")
            }
        }
        
        print("😅clearAllSavedData - end")
    }

    // MARK: - Legacy helpers

    private func resetMigrationFlagForLegacyArticles(with urls: [URL]) async throws {
        guard !urls.isEmpty else { return }

        try await dataStore.performBackgroundCoreDataOperationAsync { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            var didChange = false

            for url in urls {
                autoreleasepool {
                    guard let article = self.dataStore.fetchArticle(with: url, in: context) else {
                        DDLogInfo("[SavedPagesMigration] No WMFArticle found to reset isSavedMigrated for URL \(url.absoluteString)")
                        return
                    }

                    if article.isSavedMigrated {
                        article.isSavedMigrated = false
                        didChange = true
                    }
                }
            }

            if didChange, context.hasChanges {
                try context.save()
            }
        }
    }

    // MARK: - Helpers / Models

    private struct PageIDs: Sendable, Equatable {
        let projectID: String
        let namespaceID: Int16
        let title: String
    }

    private struct SavedArticleSnapshot: Sendable, Equatable {
        let ids: PageIDs
        let savedDate: Date
        let viewedDate: Date?
    }

    private static func getPageIDs(from articleURL: URL) -> PageIDs? {
        guard
            let siteURL = articleURL.wmf_site,
            let project = WikimediaProject(siteURL: siteURL),
            let wmfProject = project.wmfProject
        else { return nil }

        let title = (articleURL.wmf_title ?? "").normalizedForCoreData
        let namespaceID = Int16(articleURL.namespace?.rawValue ?? 0)
        
        let returnValue = PageIDs(projectID: wmfProject.id, namespaceID: namespaceID, title: title)
        return returnValue
    }

    private static func getSavedDateFromReadingLists(for url: URL, in moc: NSManagedObjectContext) -> Date? {
        guard let key = url.wmf_inMemoryKey?.databaseKey ?? url.wmf_inMemoryKey?.databaseKey else {
            return nil
        }

        let req: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        req.predicate = NSPredicate(format: "articleKey == %@ AND isDeletedLocally == NO", key)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: true)]
        req.fetchLimit = 1

        do {
            let entries = try moc.fetch(req)
            let returnValue = entries.first?.createdDate as Date?
            return returnValue
        } catch {
            DDLogError("[Mirror] ReadingListEntry fetch failed for key=\(key): \(error)")
            return nil
        }
        
    }
}

// MARK: - Private extensions

extension MWKDataStore {
    func performBackgroundCoreDataOperationAsync<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.performBackgroundCoreDataOperation { context in
                    do {
                        let value = try block(context)
                        continuation.resume(returning: value)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

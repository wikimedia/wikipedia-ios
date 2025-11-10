import Foundation
import CoreData
import WMFData
import CocoaLumberjackSwift

@objc final class WMFArticleSavedStateMigrationManager: NSObject {

    @objc static let shared = WMFArticleSavedStateMigrationManager()
    let dataStore = MWKDataStore.shared()

    override private init() {
        super.init()
    }

    // MARK: - Public API

    @objc func migrateAllIfNeeded() {
        DispatchQueue.main.async {
            self.runMigration(limit: nil)
        }
    }

    @objc func migrateIncremental() {
        DispatchQueue.main.async {
            self.runMigration(limit: 20)
        }
    }

    @objc public func removeFromSaved(forArticleObjectID objectID: NSManagedObjectID) {
        unsave(forArticleObjectID: objectID)
    }

    @objc public func clearAll() {
        clearAllSavedData()
    }

    // MARK: - Migration

    private func runMigration(limit: Int?) {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else {
            DDLogError("Missing WMFData store")
            return
        }

        dataStore.performBackgroundCoreDataOperation { wikipediaContext in
            wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
                DDLogError("Could not create WMFData background context")
                return
            }
            wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            do {
                let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                request.predicate = NSPredicate(format: "savedDate != NULL AND (isSavedMigrated == NO OR isSavedMigrated == nil)")
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

                var applyError: Error?
                wmfContext.performAndWait {
                    do {
                        for snap in snapshots {
                            try self.applySavedStateOnWMFContext(snapshot: snap, in: wmfContext, wmfDataStore: wmfDataStore)
                        }
                        if wmfContext.hasChanges { try wmfContext.save() }
                    } catch {
                        applyError = error
                    }
                }
                if let applyError { throw applyError }

                for article in articles {
                    article.isSavedMigrated = true
                }
                if wikipediaContext.hasChanges { try wikipediaContext.save() }

            } catch {
                DDLogError("WMFArticle isSavedMigrated migration error: \(error)")
            }
        }
    }

    // MARK: - Update Saved State

    @objc func unsave(forArticleObjectID objectID: NSManagedObjectID) {
        guard let wmfDataStore = WMFDataEnvironment.current.coreDataStore else { return }

        dataStore.performBackgroundCoreDataOperation { wikipediaContext in
            wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            guard let wmfContext = try? wmfDataStore.newBackgroundContext else { return }
            wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            do {
                guard let article = try? wikipediaContext.existingObject(with: objectID) as? WMFArticle else {
                    DDLogError("Revert failed: article not found for objectID \(objectID)")
                    return
                }

                article.isSavedMigrated = false
                article.savedDate = nil

                var applyError: Error?
                wmfContext.performAndWait {
                    do {
                        try self.syncSavedState(from: article, to: wmfContext, action: .unsave, wmfDataStore: wmfDataStore)
                        if wmfContext.hasChanges { try wmfContext.save() }
                    } catch {
                        applyError = error
                    }
                }
                if let applyError { throw applyError }

                if wikipediaContext.hasChanges { try wikipediaContext.save() }
            } catch {
                DDLogError("Unsave revert failed for objectID \(objectID): \(error)")
            }
        }
    }

    private func syncSavedState(from article: WMFArticle,
                                to wmfDataContext: NSManagedObjectContext,
                                action: SavedSyncAction,
                                wmfDataStore: WMFCoreDataStore) throws {
        guard let ids = getIdFromLegacyArticleURL(article) else {
            return
        }
        let projectID = ids.projectID
        let namespaceID = ids.namespaceID
        let title = ids.title

        let predicate = NSPredicate(
            format: "projectID == %@ AND namespaceID == %d AND title == %@",
            projectID, namespaceID, title
        )

        switch action {
        case .save(let date):
            // Use snapshot-based writer; caller must already be on WMF context queue
            let snap = SavedArticleSnapshot(ids: ids, savedDate: date, viewedDate: article.viewedDate)
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
            } else {
                DDLogError("[SavedPagesMigration] Error deleting savedInfo for title \(title)")
            }
            page.savedInfo = nil

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

        let batchSize = 1000

        wmfContext.performAndWait {
            do {
                var deletedCount = 0
                repeat {
                    let infos: [CDPageSavedInfo]? = try wmfDataStore.fetch(
                        entityType: CDPageSavedInfo.self,
                        predicate: nil,
                        fetchLimit: batchSize,
                        sortDescriptors: nil,
                        in: wmfContext
                    )

                    guard let infos, !infos.isEmpty else { break }

                    for info in infos {
                        wmfContext.delete(info)
                        deletedCount += 1
                    }

                    try wmfContext.save()
                } while deletedCount % batchSize == 0

            } catch {
                DDLogError("[SavedPagesMigration] Bulk clear in WMFData failed: \(error)")
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
}

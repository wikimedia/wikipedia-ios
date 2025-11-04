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

    // MARK: - Private

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

                for article in articles {
                    guard let savedDate = article.savedDate else { continue }
                    try self.syncSavedState(from: article, to: wmfContext, action: .save(date: savedDate), wmfDataStore: wmfDataStore)
                    article.isSavedMigrated = true
                }

                try wikipediaContext.save()
                try wmfContext.save()
            } catch {
                DDLogError("WMFArticle isSavedMigrated migration error: \(error)")
            }
        }
    }

    // MARK: - Revert / Unsave

    @objc func revertSavedState(forArticleObjectID objectID: NSManagedObjectID) {
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

                try self.syncSavedState(from: article, to: wmfContext, action: .unsave, wmfDataStore: wmfDataStore)

                if wikipediaContext.hasChanges { try wikipediaContext.save() }
                if wmfContext.hasChanges { try wmfContext.save() }
            } catch {
                DDLogError("Unsave revert failed for objectID \(objectID): \(error)")
            }
        }
    }


    // MARK: - Save/Unsave

    private func syncSavedState(from article: WMFArticle, to wmfDataContext: NSManagedObjectContext, action: SavedSyncAction, wmfDataStore: WMFCoreDataStore) throws {
        guard let ids = getIdFromLegacyArticleURL(article) else {
            return
        }
        let projectID = ids.projectID
        let namespaceID = ids.namespaceID
        let title = ids.title

        let predicate = NSPredicate(format: "projectID == %@ AND namespaceID == %d AND title == %@",
                                    projectID, namespaceID, title)

        switch action {
        case .save(let date):
            guard let page = try wmfDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: wmfDataContext) else {
                DDLogError("Unsave from CDSavedPage: no CDPage found for PID\(projectID) nsID\(namespaceID) title\(title)")
                return
            }

            page.title = title
            page.namespaceID = namespaceID
            page.projectID = projectID

            page.timestamp = article.viewedDate ?? date

            if let existing = page.savedDate {
                existing.savedDate = date
            } else {
                let saved = CDSavedPage(context: wmfDataContext)
                saved.savedDate = date
                page.savedDate = saved
            }

        case .unsave:
            guard let page = try wmfDataStore.fetch(entityType: CDPage.self, predicate: predicate, fetchLimit: 1, in: wmfDataContext) else {

                DDLogError("[SavedPagesMigration] Unsave: no CDPage found for PID\(projectID) nsID\(namespaceID) title\(title)")
                return
            }

            guard let page = page.first else {
                DDLogError("[SavedPagesMigration] Unsave: no CDPage found for PID\(projectID) nsID\(namespaceID) title\(title)")
                return
            }

            if let saved = page.savedDate {
                wmfDataContext.delete(saved)
            } else {
                DDLogError("[SavedPagesMigration] Error deleting page\(page), title\(title)")
            }
            page.savedDate = nil

            if page.timestamp == nil {
                DDLogInfo("[SavedPagesMigration] Deleting CDPage for \(title) — timestamp nil after unsave")
                // TODO: should delete the CDPage????????
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

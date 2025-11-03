import Foundation
import CoreData
import WMFData

@objc final class SavedStateMigrationManager: NSObject {
    @objc static let shared = SavedStateMigrationManager()

    private let queue = OperationQueue()

    override private init() {
        super.init()
        queue.name = "org.wikimedia.saved-state-migration"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
    }

    // MARK: - Public API

    /// Migrate all unmigrated WMFArticle entries
    @objc func migrateAllIfNeeded() {
        queue.addOperation {
            self.runMigration(limit: nil)
        }
    }

    /// Migrate only recent saves
    @objc func migrateIncremental() {
        queue.addOperation {
            self.runMigration(limit: 20)
        }
    }

    // MARK: - Private

    private func runMigration(limit: Int?) {
        guard
            let wikipediaContainer = MWKDataStore.shared().value(forKey: "persistentContainer") as? NSPersistentContainer, // TODO: check if there's a better way to retrieve the persistemnt container
            let wmfDataStore = WMFDataEnvironment.current.coreDataStore
        else {
            return
        }

        let wikipediaContext = wikipediaContainer.newBackgroundContext()
        wikipediaContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        guard let wmfContext = try? wmfDataStore.newBackgroundContext else {
            return
        }
        wmfContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        wikipediaContext.performAndWait {
            do {
                let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
                request.predicate = NSPredicate(format: "isSavedMigrated == NO AND savedDate != nil")
                if let limit { request.fetchLimit = limit }

                let articles = try wikipediaContext.fetch(request)
                guard !articles.isEmpty else { return }

                for article in articles {
                    try self.copySavedState(from: article, to: wmfContext)
                    article.isSavedMigrated = true
                }

                try wikipediaContext.save()
                try wmfContext.save()
            } catch {
                debugPrint("SavedStateMigration: \(error)") // TODO: handle error
            }
        }
    }

    private func copySavedState(from article: WMFArticle, to wmfDataContext: NSManagedObjectContext) throws {
        guard
            let savedDate = article.savedDate,
            let articleURL = article.url,
            let siteURL = articleURL.wmf_site,
            let project = WikimediaProject(siteURL: siteURL),
            let wmfProject = project.wmfProject
        else { return }

        let title = articleURL.wmf_title?.normalizedForCoreData ?? ""
        let namespaceID = Int16(articleURL.namespace?.rawValue ?? 0)
        let projectID = wmfProject.coreDataIdentifier

        // Fetch or create CDPage
        let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", projectID, namespaceID, title)
        let page = try fetchOrCreate(CDPage.self, predicate: predicate, in: wmfDataContext)
        page.title = title
        page.namespaceID = namespaceID
        page.projectID = projectID

        // Update or create related CDSavedPage
        if let existing = page.savedDate {
            existing.savedDate = savedDate
        } else {
            let saved = CDSavedPage(context: wmfDataContext)
            saved.savedDate = savedDate
            page.savedDate = saved
        }
    }

    private func fetchOrCreate<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate, in context: NSManagedObjectContext) throws -> T {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.fetchLimit = 1
        request.predicate = predicate
        if let existing = try context.fetch(request).first {
            return existing
        } else {
            let new = T(context: context)
            return new
        }
    }
}


// TODO: If user unsaves

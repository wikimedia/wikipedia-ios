import Foundation
import CoreData

// @unchecked Sendable: coreDataStore is an immutable let; all mutations go through backgroundContext.perform { }
public final class WMFPageInterestDataController: @unchecked Sendable {

    private let coreDataStore: WMFCoreDataStore

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
    }

    public func fetchPageInterests(project: WMFProject) async throws -> [WMFPageInterest] {
        let backgroundContext = try coreDataStore.newBackgroundContext

        return try await backgroundContext.perform { [weak self] () -> [WMFPageInterest] in
            guard let self else { return [] }
            let predicate = NSPredicate(format: "page.projectID == %@", project.id)
            let sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            let interests = try self.coreDataStore.fetch(
                entityType: CDPageInterest.self,
                predicate: predicate,
                fetchLimit: nil,
                sortDescriptors: sortDescriptors,
                in: backgroundContext
            ) ?? []

            return interests.compactMap { interest in
                guard let title = interest.page?.title,
                      let timestamp = interest.timestamp else { return nil }
                return WMFPageInterest(title: title, timestamp: timestamp)
            }
        }
    }

    public func addPageInterest(title: String, project: WMFProject) async throws {
        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let predicate = NSPredicate(
                format: "projectID == %@ && namespaceID == %@ && title == %@",
                argumentArray: [project.id, Int16(0), coreDataTitle]
            )
            let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
            page?.title = coreDataTitle
            page?.namespaceID = 0
            page?.projectID = project.id
            if page?.timestamp == nil {
                page?.timestamp = Date()
            }

            // Avoid creating duplicate CDPageInterest for the same page
            if let existingPage = page, existingPage.interest != nil {
                return
            }

            let interest = try self.coreDataStore.create(entityType: CDPageInterest.self, in: backgroundContext)
            interest.timestamp = Date()
            interest.page = page

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func removePageInterest(title: String, project: WMFProject) async throws {
        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let predicate = NSPredicate(
                format: "projectID == %@ && namespaceID == %@ && title == %@",
                argumentArray: [project.id, Int16(0), coreDataTitle]
            )
            guard let page = try self.coreDataStore.fetch(
                entityType: CDPage.self,
                predicate: predicate,
                fetchLimit: 1,
                in: backgroundContext
            )?.first else { return }

            if let interest = page.interest {
                backgroundContext.delete(interest)
                try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
            }
        }
    }
}

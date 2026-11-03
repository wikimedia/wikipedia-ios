import Foundation
import CoreData

extension WMFDiscoverReadingListDataController {

    /// A recommendation row read out of Core Data, so callers never hold managed objects.
    struct StoredRecommendation: Sendable {
        let projectID: String
        let title: String
        let displayTitle: String?
        let description: String?
        let thumbnailURLString: String?
        let extract: String?
        let timestamp: Date
        let isExpired: Bool

        var key: String { "\(projectID)|\(title)" }
    }

    func fetchStoredRecommendations(includeExpired: Bool) async throws -> [StoredRecommendation] {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        let context = try coreDataStore.newBackgroundContext

        return try await context.perform {
            let predicate = includeExpired ? nil : NSPredicate(format: "isExpired == NO")
            let sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
            let rows = try coreDataStore.fetch(entityType: CDDiscoverRecommendation.self, predicate: predicate, fetchLimit: nil, sortDescriptors: sortDescriptors, in: context) ?? []

            return rows.compactMap { row -> StoredRecommendation? in
                guard let page = row.page,
                      let projectID = page.projectID,
                      let title = page.title,
                      let timestamp = row.timestamp else {
                    return nil
                }

                return StoredRecommendation(projectID: projectID, title: title, displayTitle: row.displayTitle, description: row.pageDescription, thumbnailURLString: row.thumbnailURLString, extract: row.extract, timestamp: timestamp, isExpired: row.isExpired)
            }
        }
    }

    /// Marks every current recommendation as expired. Expired rows stay so they are not recommended twice.
    /// Generation calls this before it writes a new list. It is public so debug tools can force the same state.
    public func expireAllRecommendations() async throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        let context = try coreDataStore.newBackgroundContext

        try await context.perform {
            let predicate = NSPredicate(format: "isExpired == NO")
            let rows = try coreDataStore.fetch(entityType: CDDiscoverRecommendation.self, predicate: predicate, fetchLimit: nil, in: context) ?? []

            for row in rows {
                row.isExpired = true
            }

            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    /// Writes the new list in display order. A candidate that was recommended before reuses its row.
    func persistGeneratedList(_ candidates: [Candidate], now: Date) async throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        let context = try coreDataStore.newBackgroundContext

        try await context.perform {
            for (index, candidate) in candidates.enumerated() {
                let normalizedTitle = candidate.title.normalizedForCoreData
                let pagePredicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", candidate.project.id, NSNumber(value: 0), normalizedTitle)

                guard let page = try coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: pagePredicate, in: context) else {
                    continue
                }

                if page.title == nil {
                    page.title = normalizedTitle
                    page.namespaceID = 0
                    page.projectID = candidate.project.id
                    page.timestamp = now
                }

                let recommendation: CDDiscoverRecommendation
                if let existing = page.discoverRecommendation {
                    recommendation = existing
                } else {
                    recommendation = try coreDataStore.create(entityType: CDDiscoverRecommendation.self, in: context)
                    recommendation.page = page
                }

                recommendation.displayTitle = candidate.displayTitle
                recommendation.pageDescription = candidate.description
                recommendation.thumbnailURLString = candidate.thumbnailURL?.absoluteString
                recommendation.extract = candidate.extract
                recommendation.isExpired = false
                recommendation.timestamp = now
                recommendation.sortIndex = Int32(index)
            }

            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    func deleteStoredRecommendations() async throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        let context = try coreDataStore.newBackgroundContext

        try await context.perform {
            let rows = try coreDataStore.fetch(entityType: CDDiscoverRecommendation.self, predicate: nil, fetchLimit: nil, in: context) ?? []

            for row in rows {
                context.delete(row)
            }

            try coreDataStore.saveIfNeeded(moc: context)
        }
    }
}

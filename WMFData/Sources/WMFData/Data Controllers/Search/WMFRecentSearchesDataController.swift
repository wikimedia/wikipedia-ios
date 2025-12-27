import Foundation
import CoreData

public final class WMFRecentSearchesDataController {

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    public init() {}

    private var _backgroundContext: NSManagedObjectContext?
    public var backgroundContext: NSManagedObjectContext? {
        get {
            if _backgroundContext == nil {
                _backgroundContext = try? coreDataStore?.newBackgroundContext
                _backgroundContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
            return _backgroundContext
        } set {
            _backgroundContext = newValue
        }
    }

    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    public var hasMigrated: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasMigratedRecentSearches.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasMigratedRecentSearches.rawValue, value: newValue) }
    }
}

// MARK: - CRUD
extension WMFRecentSearchesDataController {

    public func saveRecentSearch(term: String, siteURL: URL) async throws {
        guard let coreDataStore, let moc = backgroundContext else { return }

        try await moc.perform {
            let predicate = NSPredicate(format: "term == %@ AND siteURL == %@", term, siteURL.absoluteString)
            let search = try coreDataStore.fetchOrCreate(entityType: CDRecentSearch.self, predicate: predicate, in: moc)
            search?.term = term
            search?.siteURL = siteURL.absoluteString
            search?.timestamp = Date()
            
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }

    public func fetchRecentSearches(limit: Int = 20) async throws -> [String] {
        guard let moc = backgroundContext else { return [] }

        return try await moc.perform {
            let request: NSFetchRequest<CDRecentSearch> = CDRecentSearch.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = limit

            let results = try moc.fetch(request)
            return results.compactMap { $0.term }
        }
    }

    public func deleteAll() async throws {
        guard let coreDataStore, let moc = backgroundContext else { return }

        try await moc.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = CDRecentSearch.fetchRequest()
            let delete = NSBatchDeleteRequest(fetchRequest: request)
            try moc.execute(delete)
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }

    public func deleteRecentSearch(at index: Int) async throws {
        guard let coreDataStore, let moc = backgroundContext else { return }

        try await moc.perform {
            let request: NSFetchRequest<CDRecentSearch> = CDRecentSearch.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = 20

            let results = try moc.fetch(request)
            guard index >= 0, index < results.count else { return }

            moc.delete(results[index])
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }
}

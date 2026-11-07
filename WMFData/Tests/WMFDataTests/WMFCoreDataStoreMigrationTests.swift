import Foundation
import CoreData
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// A reader updates from any model version that shipped. Their database must open with the
/// current model by lightweight migration and keep what it held.
///
/// Each new model version adds two lines to this file: its predecessor goes into
/// `previousModelVersionFileNames` and `currentModelVersionFileName` moves to the new version.
/// It also adds one test in the "Per version" section that writes rows with the previous model
/// and checks what that version introduced. The older tests stay as they are.
@Suite(.serialized)
final class WMFCoreDataStoreMigrationTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }

    /// Every model version before the current one, by `.mom` file name.
    private static let previousModelVersionFileNames = ["WMFData", "WMFData 2", "WMFData 3", "WMFData 4", "WMFData 5", "WMFData 6", "WMFData 7", "WMFData 8", "WMFData 9"]

    private static let currentModelVersionFileName = "WMFData 10"

    // MARK: - Helpers

    private func loadModel(fileName: String) throws -> NSManagedObjectModel {
        let modelDirectoryURL = try #require(WMFCoreDataStore.dataModelDirectoryURL)
        return try #require(NSManagedObjectModel(contentsOf: modelDirectoryURL.appendingPathComponent("\(fileName).mom")))
    }

    /// Writes a database with an older model, then opens it with the current model.
    /// `seed` inserts the rows with the older model's entity names, because its classes may not exist any more.
    private func migrateDatabase(from previousModel: NSManagedObjectModel, seed: @escaping @Sendable (NSManagedObjectContext) throws -> Void, verify: (WMFCoreDataStore) async throws -> Void) async throws {
        try await fixture.withConfiguredEnvironment(configure: { WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore() }) {
            let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: previousModel)
            let store = try coordinator.addPersistentStore(type: .sqlite, at: temporaryDirectory.appendingPathComponent("WMFData.sqlite"))
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            try await context.perform {
                try seed(context)
                try context.save()
            }
            try coordinator.remove(store)

            let migratedStore = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
            try await verify(migratedStore)
        }
    }

    /// `CDPage` exists in every model version, so every migration test seeds one.
    private static func insertPage(title: String, projectID: String, in context: NSManagedObjectContext) -> NSManagedObject {
        let page = NSEntityDescription.insertNewObject(forEntityName: "CDPage", into: context)
        page.setValue(title, forKey: "title")
        page.setValue(Int16(0), forKey: "namespaceID")
        page.setValue(projectID, forKey: "projectID")
        page.setValue(Date(), forKey: "timestamp")
        return page
    }

    private func fetchPageTitles(in store: WMFCoreDataStore) async throws -> [String] {
        let context = try store.newBackgroundContext
        return try await context.perform {
            let pages = try store.fetch(entityType: CDPage.self, predicate: nil, fetchLimit: nil, in: context) ?? []
            return pages.compactMap(\.title)
        }
    }

    // MARK: - Every version

    @Test
    func theCurrentModelIsTheLastVersion() throws {
        let currentModel = try loadModel(fileName: Self.currentModelVersionFileName)
        let modelDirectoryURL = try #require(WMFCoreDataStore.dataModelDirectoryURL)
        let mergedModel = try #require(NSManagedObjectModel(contentsOf: modelDirectoryURL))

        #expect(mergedModel.entityVersionHashesByName == currentModel.entityVersionHashesByName, "the .xccurrentversion must point at the last model version")
    }

    /// Opens a database written with an older model version using the current model, which must succeed by lightweight migration.
    @Test(arguments: previousModelVersionFileNames)
    func aDatabaseFromAPreviousModelVersionMigratesAndKeepsItsPages(modelFileName: String) async throws {
        let previousModel = try loadModel(fileName: modelFileName)
        let projectID = englishProject.id

        try await migrateDatabase(from: previousModel, seed: { context in
            _ = Self.insertPage(title: "Cat", projectID: projectID, in: context)
        }, verify: { migratedStore in
            let titles = try await fetchPageTitles(in: migratedStore)
            #expect(titles == ["Cat"])
        })
    }

    // MARK: - Per version

    /// Version 10 adds `CDDiscoverInterest` and its relationship on `CDPage`.
    @Test
    func version10KeepsTheDiscoverListAndTakesDiscoverInterests() async throws {
        let previousModel = try loadModel(fileName: "WMFData 9")
        #expect(previousModel.entitiesByName["CDDiscoverInterest"] == nil)
        let projectID = englishProject.id

        try await migrateDatabase(from: previousModel, seed: { context in
            let page = Self.insertPage(title: "Cat", projectID: projectID, in: context)
            let recommendation = NSEntityDescription.insertNewObject(forEntityName: "CDDiscoverRecommendation", into: context)
            recommendation.setValue(Int32(0), forKey: "sortIndex")
            recommendation.setValue(Date(), forKey: "timestamp")
            recommendation.setValue(page, forKey: "page")
        }, verify: { migratedStore in
            let context = try migratedStore.newBackgroundContext
            let recommendationTitles = try await context.perform {
                let recommendations = try migratedStore.fetch(entityType: CDDiscoverRecommendation.self, predicate: nil, fetchLimit: nil, in: context) ?? []
                return recommendations.compactMap { $0.page?.title }
            }
            #expect(recommendationTitles == ["Cat"], "a list built before the update is still there after it")

            let interestsDataController = WMFDiscoverInterestsDataController(coreDataStore: migratedStore)
            let interestsBeforeAnyPick = try await interestsDataController.fetchInterests()
            #expect(interestsBeforeAnyPick == .empty, "a reader from before the update has no Discover interests")
            try await interestsDataController.addPage(title: "Cat", project: englishProject)
            try await interestsDataController.setTopics([.music])
            let interests = try await interestsDataController.fetchInterests()
            #expect(interests == WMFDiscoverInterests(topics: [.music], pages: [WMFDiscoverInterests.Page(title: "Cat", project: englishProject)]))
        })
    }
}

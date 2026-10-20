import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData

/// `WMFCategoriesDataController` accepts an injected `WMFCoreDataStore`, so these tests build a
/// temporary store rather than leasing the global environment. Categories hang off the `CDPage`
/// rows that `WMFPageViewsDataController` creates, so page views are the fixture here.
@Suite
struct WMFCategoriesDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    /// A category attached to a read article comes back with a count of one for the window the read
    /// falls in.
    @Test
    func categoryCountsIncludeAnArticleReadInsideTheWindow() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        let readDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        try await addPageView(title: "Cat", timestamp: readDate, store: store)
        try await dataController.addCategories(categories: ["Mammals"], articleTitle: "Cat", project: enProject)

        let counts = try await dataController.fetchCategoryCounts(startDate: readDate.addingTimeInterval(-3600), endDate: Date())

        #expect(counts.count == 1)
        let entry = try #require(counts.first)
        #expect(entry.key.categoryName == "Mammals")
        #expect(entry.key.project == enProject)
        #expect(entry.value == 1)
    }

    /// Counts are per unique article, not per page view. Reading one article three times must still
    /// contribute one to its category, or a single obsessively re-read article would dominate the
    /// Activity tab's top categories.
    @Test
    func repeatedReadsOfOneArticleCountOnceForItsCategory() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        let readDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        for offset in 0..<3 {
            try await addPageView(title: "Cat", timestamp: readDate.addingTimeInterval(Double(offset) * 60), store: store)
        }
        try await dataController.addCategories(categories: ["Mammals"], articleTitle: "Cat", project: enProject)

        let counts = try await dataController.fetchCategoryCounts(startDate: readDate.addingTimeInterval(-3600), endDate: Date())

        #expect(counts.values.first == 1, "Three reads of one article are still one article in that category.")
    }

    /// Two different articles sharing a category do each contribute, which is the counterpart to the
    /// per-article rule above.
    @Test
    func distinctArticlesSharingACategoryEachCount() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        let readDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        for title in ["Cat", "Dog"] {
            try await addPageView(title: title, timestamp: readDate, store: store)
            try await dataController.addCategories(categories: ["Mammals"], articleTitle: title, project: enProject)
        }

        let counts = try await dataController.fetchCategoryCounts(startDate: readDate.addingTimeInterval(-3600), endDate: Date())

        #expect(counts.count == 1, "One category key, not one per article.")
        #expect(counts.values.first == 2)
    }

    /// The count window is a date range over page views, so an article read outside it drops out even
    /// though its category rows still exist.
    @Test
    func categoryCountsExcludeReadsOutsideTheWindow() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        let calendar = Calendar.current
        let inside = try #require(calendar.date(byAdding: .day, value: -1, to: Date()))
        let outside = try #require(calendar.date(byAdding: .day, value: -10, to: Date()))

        try await addPageView(title: "Cat", timestamp: inside, store: store)
        try await addPageView(title: "Dog", timestamp: outside, store: store)
        try await dataController.addCategories(categories: ["Mammals"], articleTitle: "Cat", project: enProject)
        try await dataController.addCategories(categories: ["Reptiles"], articleTitle: "Dog", project: enProject)

        let windowStart = try #require(calendar.date(byAdding: .day, value: -3, to: Date()))
        let counts = try await dataController.fetchCategoryCounts(startDate: windowStart, endDate: Date())

        #expect(counts.map(\.key.categoryName) == ["Mammals"], "Only the read inside the window contributes.")
    }

    /// Category titles are normalized for Core Data the same way page titles are, so a category
    /// written with spaces reads back with underscores. Callers that display these have to undo it -
    /// the Activity tab does exactly that.
    @Test
    func categoryTitlesAreNormalizedWithUnderscores() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        let readDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        try await addPageView(title: "Cat", timestamp: readDate, store: store)
        try await dataController.addCategories(categories: ["Mammals of Europe"], articleTitle: "Cat", project: enProject)

        let counts = try await dataController.fetchCategoryCounts(startDate: readDate.addingTimeInterval(-3600), endDate: Date())

        #expect(counts.map(\.key.categoryName) == ["Mammals_of_Europe"])
    }

    /// Adding the same category twice must not double the article's contribution - the relationship
    /// is a set, and a re-import of the same categories is expected to be a no-op.
    @Test
    func addingTheSameCategoryTwiceDoesNotDoubleTheCount() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        let readDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        try await addPageView(title: "Cat", timestamp: readDate, store: store)
        try await dataController.addCategories(categories: ["Mammals"], articleTitle: "Cat", project: enProject)
        try await dataController.addCategories(categories: ["Mammals"], articleTitle: "Cat", project: enProject)

        let counts = try await dataController.fetchCategoryCounts(startDate: readDate.addingTimeInterval(-3600), endDate: Date())

        #expect(counts.count == 1)
        #expect(counts.values.first == 1)
    }

    /// Categories can only attach to an article the store already knows about. Adding them for an
    /// unread article is an error rather than a silently created orphan page.
    @Test
    func addingCategoriesForAnUnknownArticleThrows() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let dataController = try WMFCategoriesDataController(coreDataStore: store)

        await #expect(throws: WMFCoreDataStoreError.missingEntity) {
            try await dataController.addCategories(categories: ["Mammals"], articleTitle: "NeverRead", project: enProject)
        }
    }

    /// Without a store there is nothing to read or write, and the initializer says so rather than
    /// handing back a controller that fails later.
    @Test
    func initializingWithoutAStoreThrows() throws {
        do {
            _ = try WMFCategoriesDataController(coreDataStore: nil)
            Issue.record("Expected initialization without a store to throw.")
        } catch WMFDataControllerError.coreDataStoreUnavailable {
            // Expected. WMFDataControllerError carries associated values in other cases, so it is
            // not Equatable and cannot be matched by value with #expect(throws:).
        }
    }

    private func addPageView(title: String, timestamp: Date, store: WMFCoreDataStore) async throws {
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)
        _ = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)
    }
}

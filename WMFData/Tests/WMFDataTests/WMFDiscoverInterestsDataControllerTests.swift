import Foundation
import CoreData
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFDiscoverInterestsDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private let spanishLanguage = WMFLanguage(languageCode: "es", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }
    private var spanishProject: WMFProject { .wikipedia(spanishLanguage) }

    private var coreDataStore: WMFCoreDataStore?

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage, spanishLanguage])
        let coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        WMFDataEnvironment.current.coreDataStore = coreDataStore
        self.coreDataStore = coreDataStore
    }

    private func page(_ title: String, project: WMFProject? = nil) -> WMFDiscoverInterests.Page {
        WMFDiscoverInterests.Page(title: title, project: project ?? englishProject)
    }

    private func addPageView(_ title: String, project: WMFProject? = nil, namespaceID: Int16 = 0, timestamp: Date) async throws {
        let pageViewsDataController = try WMFPageViewsDataController()
        _ = try await pageViewsDataController.addPageView(title: title, namespaceID: namespaceID, project: project ?? englishProject, previousPageViewObjectID: nil, timestamp: timestamp)
    }

    private func insertSavedPage(title: String, namespaceID: Int16 = 0, savedDate: Date) async throws {
        let store = try #require(coreDataStore)
        let projectID = englishProject.id
        let context = try store.newBackgroundContext
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = namespaceID
            page.projectID = projectID
            page.timestamp = savedDate

            let savedInfo = try store.create(entityType: CDPageSavedInfo.self, in: context)
            savedInfo.savedDate = savedDate
            savedInfo.page = page

            try store.saveIfNeeded(moc: context)
        }
    }

    /// Two `CDPage` rows with the same title, like a store without a uniqueness constraint can hold.
    /// A page lookup with `fetchLimit: 1` lands on the first one, which has no interest.
    private func insertDuplicatePages(title: String, interestOnLast: Bool) async throws {
        let store = try #require(coreDataStore)
        let projectID = englishProject.id
        let context = try store.newBackgroundContext
        try await context.perform {
            var lastPage: CDPage?
            for _ in 0..<2 {
                let page = try store.create(entityType: CDPage.self, in: context)
                page.title = title
                page.namespaceID = 0
                page.projectID = projectID
                page.timestamp = Date()
                lastPage = page
            }
            if interestOnLast {
                let row = try store.create(entityType: CDDiscoverInterest.self, in: context)
                row.sortIndex = 0
                row.page = lastPage
            }
            try store.saveIfNeeded(moc: context)
        }
    }

    // MARK: - Storage

    @Test
    func interestsStartEmpty() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let interests = try await WMFDiscoverInterestsDataController().fetchInterests()
            #expect(interests == .empty)
            #expect(interests.isEmpty)
            #expect(interests.count == 0)
        }
    }

    @Test
    func interestsRoundTripThroughTheStore() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDiscoverInterestsDataController()
            let interests = WMFDiscoverInterests(topics: [.music, .history], pages: [page("Cat"), page("Gato", project: spanishProject)])

            try await controller.save(interests)

            let fetched = try await controller.fetchInterests()
            #expect(fetched == interests)
            #expect(fetched.count == 4)
        }
    }

    @Test
    func savingTheSamePageTwiceKeepsOneRow() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(coreDataStore)
            let controller = WMFDiscoverInterestsDataController()

            try await controller.save(WMFDiscoverInterests(topics: [], pages: [page("Foo bar"), page("Foo_bar"), page("Cat")]))

            let context = try store.newBackgroundContext
            let rowCount = try await context.perform {
                try store.fetch(entityType: CDDiscoverInterest.self, predicate: nil, fetchLimit: nil, in: context)?.count ?? 0
            }
            #expect(try await controller.fetchInterests().pages == [page("Foo bar"), page("Cat")])
            #expect(rowCount == 2, "no row is left without a page")
        }
    }

    @Test
    func interestsAreKeptApartFromTheForYouInterests() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let forYouInterests = try WMFPageInterestDataController()
            try await forYouInterests.addPageInterest(title: "Dog", project: englishProject)
            let controller = WMFDiscoverInterestsDataController()

            try await controller.addPage(title: "Cat", project: englishProject)

            #expect(try await controller.fetchInterests().pages == [page("Cat")])
            #expect(try await forYouInterests.fetchAllPageInterests().map(\.title) == ["Dog"])
        }
    }

    @Test
    func addingAPageTwiceKeepsOneEntryWhateverTheSpacing() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDiscoverInterestsDataController()

            try await controller.addPage(title: "Feral cat", project: englishProject)
            try await controller.addPage(title: "Feral_cat", project: englishProject)
            try await controller.addPage(title: "Feral cat", project: spanishProject)

            let pages = try await controller.fetchInterests().pages
            #expect(pages == [page("Feral cat"), page("Feral cat", project: spanishProject)])
        }
    }

    @Test
    func removingAPageMatchesOnTitleAndProject() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDiscoverInterestsDataController()
            try await controller.addPage(title: "Cat", project: englishProject)
            try await controller.addPage(title: "Cat", project: spanishProject)

            try await controller.removePage(title: "Cat", project: spanishProject)

            #expect(try await controller.fetchInterests().pages == [page("Cat")])
        }
    }

    @Test
    func removeAllClearsTopicsAndPages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDiscoverInterestsDataController()
            try await controller.setTopics([.music])
            try await controller.addPage(title: "Cat", project: englishProject)

            try await controller.removeAll()

            #expect(try await controller.fetchInterests() == .empty)
        }
    }

    @Test
    func interestsDecodeWithAnUnknownTopicAndMissingKeys() throws {
        let json = Data(#"{"topics": ["music", "no-such-topic"]}"#.utf8)
        let interests = try JSONDecoder().decode(WMFDiscoverInterests.self, from: json)
        #expect(interests.topics == [.music])
        #expect(interests.pages.isEmpty)
    }

    @Test
    func interestsKeepTheOrderTheyWereSavedIn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDiscoverInterestsDataController()
            try await controller.setTopics([.history, .music, .architecture])
            try await controller.addPage(title: "Zebra", project: englishProject)
            try await controller.addPage(title: "Cat", project: englishProject)
            try await controller.removePage(title: "Zebra", project: englishProject)
            try await controller.addPage(title: "Ant", project: englishProject)

            let interests = try await controller.fetchInterests()

            #expect(interests.topics == [.history, .music, .architecture])
            #expect(interests.pages.map(\.title) == ["Cat", "Ant"])
        }
    }

    @Test
    func aSavedPageSharesItsPageWithTheRestOfTheStore() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            try await addPageView("Cat", timestamp: now)
            let store = try #require(coreDataStore)
            let controller = WMFDiscoverInterestsDataController()

            try await controller.addPage(title: "Cat", project: englishProject)
            try await controller.removePage(title: "Cat", project: englishProject)

            let context = try store.newBackgroundContext
            let (pageCount, interestCount) = try await context.perform {
                let pages = try store.fetch(entityType: CDPage.self, predicate: nil, fetchLimit: nil, in: context) ?? []
                let interests = try store.fetch(entityType: CDDiscoverInterest.self, predicate: nil, fetchLimit: nil, in: context) ?? []
                return (pages.count, interests.count)
            }
            #expect(pageCount == 1, "the page view's page is reused, and removing the interest keeps it")
            #expect(interestCount == 0)
        }
    }

    @Test
    func overlappingAddsOfOnePageKeepOneEntry() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDiscoverInterestsDataController()
            let project = englishProject

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<8 {
                    group.addTask { try await controller.addPage(title: "Cat", project: project) }
                }
                try await group.waitForAll()
            }

            #expect(try await controller.fetchInterests().pages == [page("Cat")])
        }
    }

    @Test
    func overlappingAddsOfDifferentPagesGetDistinctSortIndexes() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(coreDataStore)
            let controller = WMFDiscoverInterestsDataController()
            let project = englishProject
            let titles = (0..<8).map { "Page \($0)" }

            try await withThrowingTaskGroup(of: Void.self) { group in
                for title in titles {
                    group.addTask { try await controller.addPage(title: title, project: project) }
                }
                try await group.waitForAll()
            }

            let context = try store.newBackgroundContext
            let sortIndexes = try await context.perform {
                (try store.fetch(entityType: CDDiscoverInterest.self, predicate: nil, fetchLimit: nil, in: context) ?? []).map(\.sortIndex)
            }
            #expect(Set(try await controller.fetchInterests().pages.map(\.title)) == Set(titles))
            #expect(Set(sortIndexes).count == titles.count, "\(sortIndexes)")
        }
    }

    @Test
    func aDuplicatePageWithoutAnInterestDoesNotHideTheSelection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(coreDataStore)
            let controller = WMFDiscoverInterestsDataController()
            try await insertDuplicatePages(title: "Cat", interestOnLast: true)

            try await controller.addPage(title: "Cat", project: englishProject)
            #expect(try await controller.fetchInterests().pages == [page("Cat")], "the page is in the set, so it is not added again")

            try await controller.removePage(title: "Cat", project: englishProject)
            #expect(try await controller.fetchInterests().pages.isEmpty)

            let context = try store.newBackgroundContext
            let interestCount = try await context.perform {
                try store.fetch(entityType: CDDiscoverInterest.self, predicate: nil, fetchLimit: nil, in: context)?.count ?? 0
            }
            #expect(interestCount == 0)
        }
    }

    @Test
    func savingWithoutAStoreThrows() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDataEnvironment.current.coreDataStore = nil
            let controller = WMFDiscoverInterestsDataController()

            await #expect(throws: WMFDataControllerError.self) {
                try await controller.setTopics([.music])
            }
            await #expect(throws: WMFDataControllerError.self) {
                try await controller.fetchInterests()
            }
        }
    }

    // MARK: - Suggestions

    @Test
    func suggestionsAlternateHistoryAndSavedPagesNewestFirst() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            try await addPageView("Read one", timestamp: now)
            try await addPageView("Read two", timestamp: now.addingTimeInterval(-60))
            try await insertSavedPage(title: "Saved one", savedDate: now)
            try await insertSavedPage(title: "Saved two", savedDate: now.addingTimeInterval(-60))

            let suggestions = try await WMFDiscoverInterestsDataController().suggestedPages()

            #expect(suggestions.map(\.title) == ["Read one", "Saved one", "Read two", "Saved two"])
        }
    }

    @Test
    func suggestionsLeaveOutCurrentInterestsAndDuplicates() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            try await addPageView("Cat", timestamp: now)
            try await addPageView("Dog", timestamp: now.addingTimeInterval(-60))
            try await insertSavedPage(title: "Dog", savedDate: now)
            let controller = WMFDiscoverInterestsDataController()
            try await controller.addPage(title: "Cat", project: englishProject)

            let suggestions = try await controller.suggestedPages()

            #expect(suggestions.map(\.title) == ["Dog"])
        }
    }

    @Test
    func suggestionsKeepOnlyMainNamespacePagesAndRespectTheLimit() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            try await addPageView("Talk page", namespaceID: 1, timestamp: now)
            try await insertSavedPage(title: "User page", namespaceID: 2, savedDate: now)
            for index in 0..<30 {
                try await addPageView("Read \(index)", timestamp: now.addingTimeInterval(TimeInterval(-index)))
            }

            let controller = WMFDiscoverInterestsDataController()
            let limited = try await controller.suggestedPages(limit: 3)
            let all = try await controller.suggestedPages()

            #expect(limited.map(\.title) == ["Read 0", "Read 1", "Read 2"])
            #expect(all.count == WMFDiscoverInterestsDataController.maximumSuggestedPages)
            #expect(!all.contains { $0.title == "Talk page" || $0.title == "User page" })
        }
    }

    @Test
    func suggestionsIncludeHistoryFromEveryAppLanguage() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            try await addPageView("Cat", timestamp: now)
            try await addPageView("Gato", project: spanishProject, timestamp: now)

            let suggestions = try await WMFDiscoverInterestsDataController().suggestedPages()

            #expect(Set(suggestions) == [page("Cat"), page("Gato", project: spanishProject)])
        }
    }

    @Test
    func suggestionsOrderHistoryByRecencyAcrossLanguages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            try await addPageView("Old English read", timestamp: now.addingTimeInterval(-86_400))
            try await addPageView("Older English read", timestamp: now.addingTimeInterval(-172_800))
            try await addPageView("Fresh Spanish read", project: spanishProject, timestamp: now)

            let controller = WMFDiscoverInterestsDataController()
            let limited = try await controller.suggestedPages(limit: 1)
            let all = try await controller.suggestedPages()

            #expect(limited == [page("Fresh Spanish read", project: spanishProject)])
            #expect(all.map(\.title) == ["Fresh Spanish read", "Old English read", "Older English read"])
        }
    }

    @Test
    func suggestionsStillFillTheLimitWhenTheNewestPagesAreInTheSet() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let now = Date()
            for index in 0..<6 {
                try await addPageView("Read \(index)", timestamp: now.addingTimeInterval(TimeInterval(-index)))
            }
            let controller = WMFDiscoverInterestsDataController()
            try await controller.addPage(title: "Read 0", project: englishProject)
            try await controller.addPage(title: "Read 1", project: englishProject)

            let suggestions = try await controller.suggestedPages(limit: 3)

            #expect(suggestions.map(\.title) == ["Read 2", "Read 3", "Read 4"])
        }
    }

    @Test
    func suggestionsWithoutACoreDataStoreThrow() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDataEnvironment.current.coreDataStore = nil

            await #expect(throws: WMFDataControllerError.self) {
                try await WMFDiscoverInterestsDataController().suggestedPages()
            }
        }
    }
}

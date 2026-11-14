import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

/// Answers the user contributions request with the JSON it was given, and fails anything else.
private final class WMFTimelineMockMediaWikiService: WMFService {

    private let responseData: Data

    init(responseData: Data) {
        self.responseData = responseData
    }

    private var unexpectedRequest: Error {
        NSError(domain: "WMFTimelineMockMediaWikiService", code: 1)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        completion(.failure(unexpectedRequest))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(unexpectedRequest))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        completion(Result { try JSONDecoder().decode(T.self, from: responseData) })
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        completion(.failure(unexpectedRequest))
    }

    func clearCachedData() {}
}

@MainActor
@Suite(.serialized)
final class TimelineViewModelTests {

    private let fixture = WMFDataTestFixture()

    private var project: WMFProject {
        .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    // MARK: - Helpers

    /// A date on an earlier day, so that the seeded rows never depend on the time the test runs at.
    private func date(daysAgo: Int, hour: Int) throws -> Date {
        let calendar = Calendar.current
        let day = try #require(calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date())))
        return try #require(calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day))
    }

    private func startOfDay(daysAgo: Int) throws -> Date {
        let calendar = Calendar.current
        return try #require(calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date())))
    }

    private func coreDataStore() throws -> WMFCoreDataStore {
        let store: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore
        return try #require(store)
    }

    private func pageViewsDataController() throws -> WMFPageViewsDataController {
        try WMFPageViewsDataController(coreDataStore: try coreDataStore())
    }

    private func addRead(_ title: String, at date: Date) async throws {
        _ = try await pageViewsDataController().addPageView(title: title, namespaceID: 0, project: project, previousPageViewObjectID: nil, timestamp: date)
    }

    private func addSaved(_ title: String, at date: Date) async throws {
        let store = try coreDataStore()
        let context = try store.newBackgroundContext
        let projectID = project.id
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = 0
            page.projectID = projectID
            page.timestamp = date

            let savedInfo = try store.create(entityType: CDPageSavedInfo.self, in: context)
            savedInfo.savedDate = date
            savedInfo.page = page

            try store.saveIfNeeded(moc: context)
        }
    }

    private func addEdit(_ title: String, at date: Date) throws {
        let contribution: [String: Any] = [
            "userid": 1,
            "user": "Ada",
            "pageid": 10,
            "revid": 100,
            "parentid": 99,
            "ns": 0,
            "title": title,
            "timestamp": ISO8601DateFormatter().string(from: date)
        ]
        let response = ["query": ["usercontribs": [contribution]]]
        let data = try JSONSerialization.data(withJSONObject: response)
        WMFDataEnvironment.current.mediaWikiService = WMFTimelineMockMediaWikiService(responseData: data)
    }

    private func makeViewModel(_ authenticationState: LoginState, username: String? = nil) -> WMFActivityTabViewModel {
        let viewModel = WMFActivityTabViewModel(
            localizedStrings: .testStrings,
            dataController: WMFActivityTabDataController(),
            authenticationState: authenticationState
        )
        viewModel.timelineViewModel.setUser(username: username)
        return viewModel
    }

    private func titles(_ viewModel: WMFActivityTabViewModel) -> [[String]] {
        viewModel.sections.map { section in section.items.map(\.pageTitle) }
    }

    private func item(_ title: String, in viewModel: WMFActivityTabViewModel) throws -> (item: TimelineItem, section: TimelineViewModel.TimelineSection) {
        let section = try #require(viewModel.sections.first { section in section.items.contains { $0.pageTitle == title } })
        let item = try #require(section.items.first { $0.pageTitle == title })
        return (item, section)
    }

    private func waitForPageViewDeletion(of title: String) async throws {
        let dataController = WMFActivityTabDataController()
        try await waitForActivityTabCondition {
            let remaining = try await dataController.fetchTimelineReadArticles()
            return !remaining.values.flatMap { $0 }.contains { $0.pageTitle == title }
        }
    }

    // MARK: - Fetching

    @Test
    func noActivityGivesOneEmptyTodaySection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)

            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [[]])
            #expect(viewModel.sections.first.map { Calendar.current.isDateInToday($0.date) } == true)
            #expect(viewModel.shouldShowEmptyState)
        }
    }

    @Test
    func anEmptyFetchKeepsTheExistingTodaySection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()
            let today = try #require(viewModel.sections.first)

            await viewModel.timelineViewModel.fetch()

            #expect(viewModel.sections.count == 1)
            #expect(viewModel.sections.first === today)
        }
    }

    @Test
    func readItemsAreGroupedByDayWithTheNewestFirst() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 3, hour: 9))
            try await addRead("Dog", at: try date(daysAgo: 2, hour: 9))
            try await addRead("Emu", at: try date(daysAgo: 2, hour: 15))
            let viewModel = makeViewModel(.loggedIn)

            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [["Emu", "Dog"], ["Cat"]])
            let expectedDays = [try startOfDay(daysAgo: 2), try startOfDay(daysAgo: 3)]
            #expect(viewModel.sections.map(\.date) == expectedDays)
        }
    }

    @Test
    func aPermanentAccountSeesReadSavedAndEditedItems() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Read", at: try date(daysAgo: 2, hour: 9))
            try await addSaved("Saved", at: try date(daysAgo: 2, hour: 10))
            try addEdit("Edited", at: try date(daysAgo: 2, hour: 11))
            let viewModel = makeViewModel(.loggedIn, username: "Ada")

            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [["Edited", "Saved", "Read"]])
        }
    }

    @Test
    func withoutAUsernameNoEditsAreRequested() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Read", at: try date(daysAgo: 2, hour: 9))
            try addEdit("Edited", at: try date(daysAgo: 2, hour: 11))
            let viewModel = makeViewModel(.loggedIn, username: nil)

            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [["Read"]])
        }
    }

    @Test
    func setUserChangesWhoseEditsAreFetched() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try addEdit("Edited", at: try date(daysAgo: 2, hour: 11))
            let viewModel = makeViewModel(.loggedIn, username: nil)

            viewModel.timelineViewModel.setUser(username: "Ada")
            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [["Edited"]])
        }
    }

    @Test
    func accountsThatAreNotPermanentSeeOnlyReadItems() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Read", at: try date(daysAgo: 2, hour: 9))
            try await addSaved("Saved", at: try date(daysAgo: 2, hour: 10))
            try addEdit("Edited", at: try date(daysAgo: 2, hour: 11))

            for authenticationState in [LoginState.loggedOut, .temp] {
                let viewModel = makeViewModel(authenticationState, username: "Ada")

                await viewModel.timelineViewModel.fetch()

                #expect(titles(viewModel) == [["Read"]])
            }
        }
    }

    @Test
    func whenEveryItemIsFilteredOutATodaySectionRemains() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addSaved("Saved", at: try date(daysAgo: 2, hour: 10))
            let viewModel = makeViewModel(.loggedOut)

            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [[]])
            #expect(viewModel.sections.first.map { Calendar.current.isDateInToday($0.date) } == true)

            let today = try #require(viewModel.sections.first)
            await viewModel.timelineViewModel.fetch()

            #expect(viewModel.sections.first === today)
        }
    }

    @Test
    func aRefetchAddsNewItemsToTheExistingSectionAndKeepsLoadedDetails() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 2, hour: 9))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()
            let section = try #require(viewModel.sections.first)
            section.items[0].description = "Loaded by the row"

            try await addRead("Dog", at: try date(daysAgo: 2, hour: 15))
            await viewModel.timelineViewModel.fetch()

            #expect(viewModel.sections.first === section)
            #expect(titles(viewModel) == [["Dog", "Cat"]])
            #expect(section.items[1].description == "Loaded by the row")
        }
    }

    @Test
    func aRefetchWithTheSameItemsLeavesThemUntouched() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 2, hour: 9))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()
            let section = try #require(viewModel.sections.first)
            section.items[0].description = "Loaded by the row"

            await viewModel.timelineViewModel.fetch()

            #expect(viewModel.sections.first === section)
            #expect(section.items[0].description == "Loaded by the row")
        }
    }

    @Test
    func aRefetchDropsASectionWhoseItemsAreGone() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 3, hour: 9))
            try await addRead("Dog", at: try date(daysAgo: 2, hour: 9))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()

            try await pageViewsDataController().deletePageView(title: "Cat", namespaceID: 0, project: project)
            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [["Dog"]])
        }
    }

    @Test
    func aFailedFetchLeavesTheSectionsAlone() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 2, hour: 9))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()

            WMFDataEnvironment.current.coreDataStore = nil
            await viewModel.timelineViewModel.fetch()

            #expect(titles(viewModel) == [["Cat"]])
        }
    }

    // MARK: - Deleting

    @Test
    func deletingAnItemKeepsTheRestOfItsSection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 2, hour: 9))
            try await addRead("Dog", at: try date(daysAgo: 2, hour: 15))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()
            let target = try item("Cat", in: viewModel)

            viewModel.timelineViewModel.deletePage(item: target.item, section: target.section)

            #expect(titles(viewModel) == [["Dog"]])
            try await waitForPageViewDeletion(of: "Cat")
            await viewModel.timelineViewModel.fetch()
            #expect(titles(viewModel) == [["Dog"]])
        }
    }

    @Test
    func deletingTheLastItemOfASectionRemovesTheSection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 3, hour: 9))
            try await addRead("Dog", at: try date(daysAgo: 2, hour: 9))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()
            let target = try item("Cat", in: viewModel)

            viewModel.timelineViewModel.deletePage(item: target.item, section: target.section)

            #expect(titles(viewModel) == [["Dog"]])
            try await waitForPageViewDeletion(of: "Cat")
        }
    }

    /// Business rule from T409200: with no items left there is still a section that says Today.
    @Test
    func deletingTheLastItemLeavesAnEmptyTodaySection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: try date(daysAgo: 2, hour: 9))
            let viewModel = makeViewModel(.loggedIn)
            await viewModel.timelineViewModel.fetch()
            let target = try item("Cat", in: viewModel)

            viewModel.timelineViewModel.deletePage(item: target.item, section: target.section)

            #expect(titles(viewModel) == [[]])
            #expect(viewModel.sections.first.map { Calendar.current.isDateInToday($0.date) } == true)
            #expect(viewModel.shouldShowEmptyState)
            try await waitForPageViewDeletion(of: "Cat")
        }
    }

    // MARK: - Tapping

    @Test
    func tapsReachTheirCallbacks() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let timelineViewModel = TimelineViewModel(dataController: WMFActivityTabDataController())
            let item = TimelineItem(id: "1", date: Date(), titleHtml: "Cat", projectID: project.id, pageTitle: "Cat", url: nil, namespaceID: 0)
            var tapped: [String] = []
            var editTapped: [String] = []
            timelineViewModel.onTapArticle = { tapped.append($0.id) }
            timelineViewModel.onTapEditArticle = { editTapped.append($0.id) }

            timelineViewModel.onTap(item)
            #expect(tapped == ["1"])
            #expect(editTapped.isEmpty)

            timelineViewModel.onTapEdit(item)
            #expect(tapped == ["1"])
            #expect(editTapped == ["1"])
        }
    }

    // MARK: - Images

    @Test
    func loadImageReturnsNilWithoutAURL() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let timelineViewModel = TimelineViewModel(dataController: WMFActivityTabDataController())

            let imageWithoutAString = try await timelineViewModel.loadImage(imageURLString: nil)
            let imageWithAnInvalidURL = try await timelineViewModel.loadImage(imageURLString: "")

            #expect(imageWithoutAString == nil)
            #expect(imageWithAnInvalidURL == nil)
        }
    }
}

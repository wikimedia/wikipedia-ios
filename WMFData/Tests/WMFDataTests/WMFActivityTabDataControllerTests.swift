import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData

@Suite
struct WMFActivityTabDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    /// The window the Activity tab labels as a week must be seven days, not eight. Reading from
    /// seven days ago is outside it; reading from six days ago is inside.
    @Test
    func timeReadPast7DaysCoversSevenDays() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sixDaysAgo = try #require(calendar.date(byAdding: .day, value: -6, to: startOfToday)?.addingTimeInterval(3600))
        let sevenDaysAgo = try #require(calendar.date(byAdding: .day, value: -7, to: startOfToday)?.addingTimeInterval(3600))

        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let insideObjectID = try #require(try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: sixDaysAgo))
        let outsideObjectID = try #require(try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: sevenDaysAgo))

        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: insideObjectID, numberOfSeconds: 600)
        try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: outsideObjectID, numberOfSeconds: 1200)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeRead = try #require(try await dataController.getTimeReadPast7Days())

        #expect(timeRead.0 == 0)
        #expect(timeRead.1 == 10, "Only the reading from inside the seven day window should be counted.")
    }

    @Test
    func timeReadPast7DaysConvertsMinutesToHoursAndMinutes() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        // Two page views today, each an hour of reading, so 2h 0m — and each at the ceiling, to
        // confirm the ceiling is per page view rather than a cap on the reported total.
        for title in ["Cat", "Dog"] {
            let objectID = try #require(try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: Date()))
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: objectID, numberOfSeconds: WMFPageViewsDataController.inflatedPageViewSecondsCeiling)
        }

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeRead = try #require(try await dataController.getTimeReadPast7Days())

        #expect(timeRead.0 == 2)
        #expect(timeRead.1 == 0)
    }

    /// Articles read is a rolling thirty day window, so a read from thirty-one days ago must not
    /// keep inflating the number.
    @Test
    func articlesReadCountsOnlyTheLastThirtyDays() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let calendar = Calendar.current
        let now = Date()
        let inside = try #require(calendar.date(byAdding: .day, value: -29, to: now))
        let outside = try #require(calendar.date(byAdding: .day, value: -31, to: now))

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: inside)
        _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: outside)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let articlesRead = try await dataController.getArticlesRead()

        #expect(articlesRead == 1, "Only the read inside the thirty day window should be counted.")
    }

    /// The four weekly buckets come back oldest first, so the chart reads left to right in time
    /// order. Each read uses its own title so a bucket's total is just its number of reads.
    @Test
    func weeklyReadsThisMonthReturnsFourBucketsOldestFirst() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let calendar = Calendar.current
        let now = Date()
        let readsByWeek: [(dayOffset: Int, titles: [String])] = [
            (-1, ["A1"]),
            (-8, ["B1", "B2"]),
            (-15, ["C1", "C2", "C3"]),
            (-22, ["D1", "D2", "D3", "D4"])
        ]

        for (dayOffset, titles) in readsByWeek {
            let timestamp = try #require(calendar.date(byAdding: .day, value: dayOffset, to: now))
            for title in titles {
                _ = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)
            }
        }

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let weeklyReads = try await dataController.getWeeklyReadsThisMonth()

        #expect(weeklyReads == [4, 3, 2, 1], "Three weeks back through this week, oldest bucket first.")
    }

    /// Reading the same article twice in a day collapses to one timeline entry, and the entry kept
    /// is the first visit of that day rather than the most recent one.
    @Test
    func timelineReadArticlesKeepsTheFirstVisitOfEachDay() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let calendar = Calendar.current
        let day = try #require(calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: Date())))
        let morning = day.addingTimeInterval(9 * 3600)
        let afternoon = day.addingTimeInterval(15 * 3600)
        let previousDay = try #require(calendar.date(byAdding: .day, value: -1, to: day)).addingTimeInterval(11 * 3600)

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: morning)
        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: afternoon)
        _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: afternoon)
        _ = try await pageViewsDataController.addPageView(title: "Emu", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: previousDay)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let timeline = try await dataController.fetchTimelineReadArticles()

        #expect(timeline.count == 2, "One bucket per calendar day of reading.")

        let dayItems = try #require(timeline[day])
        #expect(dayItems.map(\.pageTitle) == ["Cat", "Dog"], "Items within a day are sorted oldest first.")
        #expect(dayItems.allSatisfy { $0.itemType == .read })

        let cat = try #require(dayItems.first)
        #expect(abs(cat.date.timeIntervalSince(morning)) < 1, "The repeated Cat read collapses to the first visit of the day.")
    }

    /// The most recent read drives the reading-streak copy, so it must be the newest page view, and
    /// nil rather than a placeholder date when nothing has been read.
    @Test
    func mostRecentReadDateTimeReturnsTheNewestPageViewOrNil() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let calendar = Calendar.current
        let older = try #require(calendar.date(byAdding: .day, value: -3, to: Date()))
        let newer = try #require(calendar.date(byAdding: .day, value: -1, to: Date()))

        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: older)
        _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: newer)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        let mostRecent = try #require(try await dataController.getMostRecentReadDateTime())
        #expect(abs(mostRecent.timeIntervalSince(newer)) < 1)

        let emptyStore = try await fixture.makeTemporaryCoreDataStore()
        let emptyDataController = WMFActivityTabDataController(coreDataStore: emptyStore)
        let noReads = try await emptyDataController.getMostRecentReadDateTime()
        #expect(noReads == nil, "No reads means no date, not the epoch or now.")
    }

    /// Deleting through a timeline item has to resolve the project from the item's projectID string
    /// and remove the underlying page view, so the row does not reappear on the next fetch.
    @Test
    func deletePageViewForTimelineItemRemovesOnlyThatArticle() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let timestamp = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)
        _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        try await dataController.deletePageView(for: timelineItem(pageTitle: "Cat", projectID: enProject.id, date: timestamp))

        let remaining = try await dataController.fetchTimelineReadArticles().values.flatMap { $0 }
        #expect(remaining.map(\.pageTitle) == ["Dog"])
    }

    /// A timeline item whose projectID does not parse must be a no-op rather than deleting the wrong
    /// row or throwing into the caller.
    @Test
    func deletePageViewForItemWithUnparseableProjectDoesNothing() async throws {
        let store = try await fixture.makeTemporaryCoreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        let timestamp = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)

        #expect(WMFProject(id: "not-a-project") == nil, "Premise of this test: the identifier does not resolve.")

        let dataController = WMFActivityTabDataController(coreDataStore: store)
        try await dataController.deletePageView(for: timelineItem(pageTitle: "Cat", projectID: "not-a-project", date: timestamp))

        let remaining = try await dataController.fetchTimelineReadArticles().values.flatMap { $0 }
        #expect(remaining.map(\.pageTitle) == ["Cat"], "The read should survive an unresolvable project.")
    }

    /// TimelineItem identity is the id alone. The timeline merges read, saved and edit entries for
    /// the same article, so two entries that differ in every other field are still the same item.
    @Test
    func timelineItemEqualityUsesTheIdentifierAlone() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let read = TimelineItem(id: "shared-id", date: date, titleHtml: "Cat", projectID: "wikipedia~en", pageTitle: "Cat", url: nil, namespaceID: 0, itemType: .read)
        let saved = TimelineItem(id: "shared-id", date: date.addingTimeInterval(3600), titleHtml: "Dog", projectID: "wikipedia~de", pageTitle: "Dog", url: nil, namespaceID: 14, itemType: .saved)
        let other = TimelineItem(id: "other-id", date: date, titleHtml: "Cat", projectID: "wikipedia~en", pageTitle: "Cat", url: nil, namespaceID: 0, itemType: .read)

        #expect(read == saved)
        #expect(read != other)
    }

    /// An edit becomes a timeline item that keeps both revision identifiers, which the diff link
    /// needs, and is typed .edit so the row draws its icon.
    @Test
    func timelineItemFromArticleEditCarriesRevisionIdentifiers() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url = try #require(URL(string: "https://en.wikipedia.org/wiki/Cat"))
        let edit = ArticleEdit(pageID: 42, revisionID: 7, parentRevisionID: 6, title: "Cat", date: date, projectID: enProject.id, url: url)

        let item = TimelineItem(articleEdit: edit)

        #expect(item.id == "42-7")
        #expect(item.itemType == .edit)
        #expect(item.revisionID == 7)
        #expect(item.parentRevisionID == 6)
        #expect(item.pageTitle == "Cat")
        #expect(item.titleHtml == "Cat")
        #expect(item.namespaceID == 0, "Contributions are article space.")
        #expect(item.url == url)
    }

    private func timelineItem(pageTitle: String, projectID: String, date: Date) -> TimelineItem {
        TimelineItem(
            id: "read~\(projectID)~\(pageTitle)~\(date.timeIntervalSince1970)",
            date: date,
            titleHtml: pageTitle,
            projectID: projectID,
            pageTitle: pageTitle,
            url: nil,
            namespaceID: 0,
            itemType: .read
        )
    }
}

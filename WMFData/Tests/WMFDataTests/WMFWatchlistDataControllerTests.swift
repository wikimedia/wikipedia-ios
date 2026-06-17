import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFWatchlistDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))

    @Test
    func allWatchlistProjects() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let allProjects = controller.allWatchlistProjects()

            #expect([enProject, esProject, .commons, .wikidata] == allProjects)
        }
    }

    @Test
    func savingAndLoadingFilterSettings() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [.wikidata, .commons], latestRevisions: .latestRevision, activity: .seenChanges, automatedContributions: .bot, significance: .minorEdits, userRegistration: .registered, offTypes: [.categoryChanges, .loggedActions])

            controller.saveFilterSettings(filterSettings)
            let loadedFilterSettings = controller.loadFilterSettings()

            #expect(filterSettings == loadedFilterSettings)
        }
    }

    @Test
    func onOffWatchlistProjects() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [.wikidata, .commons], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])

            controller.saveFilterSettings(filterSettings)

            #expect(controller.onWatchlistProjects() == [enProject, esProject])
            #expect(controller.offWatchlistProjects() == [.wikidata, .commons])
        }
    }

    @Test
    func allOffChangeTypes() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [.categoryChanges, .pageCreations])

            controller.saveFilterSettings(filterSettings)

            #expect(controller.allChangeTypes() == [.pageEdits, .pageCreations, .categoryChanges, .wikidataEdits, .loggedActions])
            #expect(controller.offChangeTypes() == [.categoryChanges, .pageCreations])
        }
    }

    @Test
    func activeFilterCount1() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [.commons, .wikidata], latestRevisions: .notTheLatestRevision, activity: .seenChanges, automatedContributions: .bot, significance: .minorEdits, userRegistration: .registered, offTypes: [])

            controller.saveFilterSettings(filterSettings)

            #expect(controller.activeFilterCount() == 6)
        }
    }

    @Test
    func activeFilterCount2() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .latestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [.categoryChanges])

            controller.saveFilterSettings(filterSettings)

            #expect(controller.activeFilterCount() == 2)
        }
    }

    @Test
    func activeFilterCount3() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [.commons, .wikidata, enProject], latestRevisions: .latestRevision, activity: .unseenChanges, automatedContributions: .human, significance: .nonMinorEdits, userRegistration: .unregistered, offTypes: [.categoryChanges, .loggedActions, .pageCreations, .pageEdits, .wikidataEdits])

            controller.saveFilterSettings(filterSettings)

            #expect(controller.activeFilterCount() == 13)
        }
    }

    @Test
    func fetchWatchlistWithDefaultFilter() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()

            let watchlist = try await controller.fetchWatchlist()

            #expect(watchlist.items.count == 82)
            #expect(watchlist.activeFilterCount == 0)
            #expect(watchlist.items.filter { $0.project == enProject }.count == 38)
            #expect(watchlist.items.filter { $0.project == esProject }.count == 13)
            #expect(watchlist.items.filter { $0.project == .wikidata }.count == 28)
            #expect(watchlist.items.filter { $0.project == .commons }.count == 3)

            let first = try #require(watchlist.items.first)
            #expect(first.title == "Talk:Cat")
            #expect(first.username == "CatLover 1137")
            #expect(first.revisionID == 1157699533)
            #expect(first.oldRevisionID == 1157699360)
            #expect(first.isAnon == false)
            #expect(first.isBot == false)
            #expect(first.commentWikitext == "/* I disagree with the above comment */ Reply")
            #expect(first.commentHtml == "<span dir=\"auto\"><span class=\"autocomment\"><a href=\"/wiki/Talk:Cat#I_disagree_with_the_above_comment\" title=\"Talk:Cat\">→‎I disagree with the above comment</a>: </span> Reply</span>")
            #expect(first.byteLength == 4246)
            #expect(first.oldByteLength == 4071)
            #expect(first.project == enProject)
            let expectedDate = try testDate()
            #expect(first.timestamp == expectedDate)
        }
    }

    @Test
    func fetchWatchlistWithProjectFilter() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [enProject, esProject], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
            controller.saveFilterSettings(filterSettings)

            let watchlist = try await controller.fetchWatchlist()

            #expect(watchlist.items.count == 31)
            #expect(watchlist.activeFilterCount == 2)
            #expect(watchlist.items.filter { $0.project == enProject }.count == 0)
            #expect(watchlist.items.filter { $0.project == esProject }.count == 0)
            #expect(watchlist.items.filter { $0.project == .wikidata }.count == 28)
            #expect(watchlist.items.filter { $0.project == .commons }.count == 3)
        }
    }

    @Test
    func fetchWatchlistWithAllProjectsPlusOneFilter() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [enProject, esProject, .wikidata, .commons], latestRevisions: .latestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
            controller.saveFilterSettings(filterSettings)

            let watchlist = try await controller.fetchWatchlist()

            #expect(watchlist.activeFilterCount == 5)
        }
    }

    @Test
    func fetchWatchlistWithBotsFilter() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let filterSettings = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .bot, significance: .all, userRegistration: .all, offTypes: [])
            controller.saveFilterSettings(filterSettings)

            let watchlist = try await controller.fetchWatchlist()

            #expect(watchlist.items.count == 2)
            #expect(watchlist.activeFilterCount == 1)
            #expect(watchlist.items.filter { $0.isBot == false }.count == 0)
        }
    }

    @Test
    func fetchWatchlistWithNoCacheAndNoInternetConnection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            controller.service = WMFMockServiceNoInternetConnection()

            let error = try #require(await #expect(throws: WMFDataControllerError.self) {
                _ = try await controller.fetchWatchlist()
            })

            guard case .serviceError(let underlyingError) = error else {
                Issue.record("Expected serviceError, got \(error)")
                return
            }

            let nsError = underlyingError as NSError
            #expect(nsError.domain == NSURLErrorDomain)
            #expect(nsError.code == NSURLErrorNotConnectedToInternet)
        }
    }

    @Test
    func fetchWatchlistWithCacheAndNoInternetConnection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()
            let connectedWatchlist = try await controller.fetchWatchlist()

            controller.service = WMFMockServiceNoInternetConnection()

            let disconnectedAndCachedWatchlist = try await controller.fetchWatchlist()

            #expect(connectedWatchlist.items.count == 82)
            #expect(disconnectedAndCachedWatchlist.items.count == 82)
        }
    }

    @Test
    func postWatchArticleExpiryNever() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()

            try await controller.watch(title: "Cat", project: enProject, expiry: .never)
        }
    }

    @Test
    func postWatchArticleExpiryDate() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()

            try await controller.watch(title: "Cat", project: enProject, expiry: .oneMonth)
        }
    }

    @Test
    func postUnwatchArticle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()

            try await controller.unwatch(title: "Cat", project: enProject)
        }
    }

    @Test
    func postRollbackArticle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()

            let result = try await controller.rollback(title: "Cat", project: enProject, username: "Amigao")

            #expect(result.newRevisionID == 573955)
            #expect(result.oldRevisionID == 573953)
        }
    }

    @Test
    func postUndoArticle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFWatchlistDataController()

            let result = try await controller.undo(title: "Cat", revisionID: 1155871225, summary: "Testing", username: "Amigao", project: enProject)

            #expect(result.newRevisionID == 573989)
            #expect(result.oldRevisionID == 573988)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [
            WMFLanguage(languageCode: "en", languageVariantCode: nil),
            WMFLanguage(languageCode: "es", languageVariantCode: nil)
        ])
        WMFDataEnvironment.current.mediaWikiService = WMFMockWatchlistMediaWikiService()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    private func testDate() throws -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 5
        dateComponents.day = 30
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")
        dateComponents.hour = 11
        dateComponents.minute = 37
        dateComponents.second = 31

        return try #require(Calendar.current.date(from: dateComponents))
    }
}

private extension WMFWatchlistDataController {
    func fetchWatchlist() async throws -> WMFWatchlist {
        try await withCheckedThrowingContinuation { continuation in
            fetchWatchlist { result in
                continuation.resume(with: result)
            }
        }
    }

    func watch(title: String, project: WMFProject, expiry: WMFWatchlistExpiryType) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            watch(title: title, project: project, expiry: expiry) { result in
                continuation.resume(with: result)
            }
        }
    }

    func unwatch(title: String, project: WMFProject) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            unwatch(title: title, project: project) { result in
                continuation.resume(with: result)
            }
        }
    }

    func rollback(title: String, project: WMFProject, username: String) async throws -> WMFUndoOrRollbackResult {
        try await withCheckedThrowingContinuation { continuation in
            rollback(title: title, project: project, username: username) { result in
                continuation.resume(with: result)
            }
        }
    }

    func undo(title: String, revisionID: UInt, summary: String, username: String, project: WMFProject) async throws -> WMFUndoOrRollbackResult {
        try await withCheckedThrowingContinuation { continuation in
            undo(title: title, revisionID: revisionID, summary: summary, username: username, project: project) { result in
                continuation.resume(with: result)
            }
        }
    }
}

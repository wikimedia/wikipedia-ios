import Foundation
import os
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// One generation run of the Discover list: what it tells its observers, what stops it, and what
/// a stopped run leaves behind.
@Suite(.serialized)
final class WMFDiscoverReadingListGenerationRunTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }
    private let enabledSettings = WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests)

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    /// A controller whose related pages requests answer at once from the fixture.
    private func makeAnsweringController() -> WMFDiscoverReadingListDataController {
        WMFDiscoverReadingListDataController(relatedPagesDataController: WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get")))
    }

    /// A controller whose related pages requests never answer until the run is stopped.
    private func makeHangingController(service: WMFHangingBasicService, generationTimeout: Duration = WMFDiscoverReadingListDataController.defaultGenerationTimeout) -> WMFDiscoverReadingListDataController {
        WMFDiscoverReadingListDataController(relatedPagesDataController: WMFRelatedPagesDataController(basicService: service), generationTimeout: generationTimeout)
    }

    private func addInterest(_ title: String) async throws {
        try await WMFDiscoverInterestsDataController().addPage(title: title, project: englishProject)
    }

    /// A controller whose topic requests never answer until the run is stopped. The related pages
    /// requests answer at once, so only the topic request can hold the run.
    private func makeHangingTopicsController(service: WMFHangingBasicService, generationTimeout: Duration) -> WMFDiscoverReadingListDataController {
        let homeDataController = WMFHomeDataController(basicService: service, userDefaultsStore: WMFMockKeyValueStore())
        return WMFDiscoverReadingListDataController(relatedPagesDataController: WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get")), homeDataController: homeDataController, generationTimeout: generationTimeout)
    }

    /// Counts the list state notifications posted while the returned token lives.
    private func observeListStatePosts() -> (count: OSAllocatedUnfairLock<Int>, token: NSObjectProtocol) {
        let count = OSAllocatedUnfairLock(initialState: 0)
        let token = NotificationCenter.default.addObserver(forName: WMFNSNotification.discoverListStateDidChange, object: nil, queue: nil) { _ in
            count.withLock { $0 += 1 }
        }
        return (count, token)
    }

    // MARK: - Notifications

    @Test
    func aRunPostsTheListStateWhenItStartsAndWhenItEnds() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeAnsweringController()
            try await controller.saveSettings(enabledSettings)
            let posts = observeListStatePosts()
            defer { NotificationCenter.default.removeObserver(posts.token) }

            _ = try await controller.generateRecommendations()

            #expect(posts.count.withLock { $0 } == 2)
            #expect(await controller.isGenerating == false)
        }
    }

    // MARK: - Stopping a run

    @Test
    func savingNewInputsStopsTheRunInFlight() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let service = WMFHangingBasicService()
            let controller = makeHangingController(service: service)
            try await controller.saveSettings(enabledSettings)

            let run = Task { try await controller.generateRecommendations() }
            await service.waitForFirstRequest()
            #expect(await controller.isGenerating == true)

            var newSettings = enabledSettings
            newSettings.articleCount = 3
            try await controller.saveSettings(newSettings)

            #expect(await controller.isGenerating == false)
            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await run.value
            }
            #expect(try await controller.fetchStoredRecommendations(includeExpired: true).isEmpty, "a stopped run stores nothing")
        }
    }

    @Test
    func aChangeUndoneDuringTheRunKeepsThePreviousList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let answeringController = makeAnsweringController()
            try await answeringController.saveSettings(enabledSettings)
            let previousList = try await answeringController.generateRecommendations()
            var changedSettings = enabledSettings
            changedSettings.articleCount = 3
            try await answeringController.saveSettings(changedSettings)

            let service = WMFHangingBasicService()
            let controller = makeHangingController(service: service)
            let run = Task { try await controller.generateRecommendationsIfNeeded() }
            await service.waitForFirstRequest()
            try await controller.saveSettings(enabledSettings)

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await run.value
            }
            #expect(try await controller.fetchCurrentRecommendations() == previousList, "the previous list is neither expired nor replaced")
            #expect(try await controller.isGenerationDue() == false, "the list matches the settings again")
        }
    }

    @Test
    func aStoppedRunDoesNotPostTheEndTwice() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let service = WMFHangingBasicService()
            let controller = makeHangingController(service: service)
            try await controller.saveSettings(enabledSettings)
            let posts = observeListStatePosts()
            defer { NotificationCenter.default.removeObserver(posts.token) }

            let run = Task { try await controller.generateRecommendations() }
            await service.waitForFirstRequest()
            var newSettings = enabledSettings
            newSettings.articleCount = 3
            try await controller.saveSettings(newSettings)
            _ = try? await run.value

            #expect(posts.count.withLock { $0 } == 2, "one post for the start, one for the settings change that stopped the run")
        }
    }

    // MARK: - Time budget

    @Test
    func aRunOverTheBudgetStopsAndKeepsThePreviousList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let answeringController = makeAnsweringController()
            try await answeringController.saveSettings(enabledSettings)
            let previousList = try await answeringController.generateRecommendations()
            var changedSettings = enabledSettings
            changedSettings.articleCount = 3
            try await answeringController.saveSettings(changedSettings)

            let service = WMFHangingBasicService()
            let controller = makeHangingController(service: service, generationTimeout: .milliseconds(1))
            let posts = observeListStatePosts()
            defer { NotificationCenter.default.removeObserver(posts.token) }

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await controller.generateRecommendations()
            }

            #expect(await controller.isGenerating == false)
            #expect(posts.count.withLock { $0 } == 2, "the start and the end")
            #expect(try await controller.fetchCurrentRecommendations() == previousList)
            #expect(try await controller.isGenerationDue() == true, "the next check tries again")
        }
    }

    /// The seeds of a topic come from the Home data controller. Its request must stop with the run
    /// too, or the run waits for the network for as long as it takes.
    @Test
    func aRunOverTheBudgetStopsAHangingTopicRequest() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFDiscoverInterestsDataController().setTopics([.books])
            let service = WMFHangingBasicService()
            let controller = makeHangingTopicsController(service: service, generationTimeout: .milliseconds(1))
            try await controller.saveSettings(enabledSettings)

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await controller.generateRecommendations()
            }

            #expect(service.requestCount == 1, "the topic request started and the run did not get past it")
            #expect(await controller.isGenerating == false)
            #expect(try await controller.fetchStoredRecommendations(includeExpired: true).isEmpty, "a stopped run stores nothing")
        }
    }

    /// One topic search takes seconds, so a run that asks for its topics one after the other can
    /// run out of its budget with topics alone. The topics are asked for at the same time.
    @Test
    func aRunAsksForEveryTopicAtTheSameTime() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFDiscoverInterestsDataController().setTopics([.books, .music])
            let service = WMFHangingBasicService()
            let controller = makeHangingTopicsController(service: service, generationTimeout: .seconds(600))
            try await controller.saveSettings(enabledSettings)

            let run = Task { try await controller.generateRecommendations() }
            await service.waitForRequest(count: 2)

            #expect(service.openRequestCount(whenRequestStarted: 2) == 1, "the first topic request is still open when the second one starts")

            var newSettings = enabledSettings
            newSettings.articleCount = 3
            try await controller.saveSettings(newSettings)
            _ = try? await run.value
            #expect(await controller.isGenerating == false)
        }
    }

    // MARK: - A run after a stopped run

    /// A stopped run can still be inside its write. The next run starts its work after the stopped
    /// run has ended, so the two never write the list at the same time. The service here keeps a
    /// cancelled request open, like a request already handed to the network.
    @Test
    func aRunStartsAfterTheStoppedRunHasEnded() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let service = WMFHangingBasicService(stopsOnCancel: false)
            let controller = makeHangingController(service: service)
            try await controller.saveSettings(enabledSettings)

            let stoppedRun = Task { try await controller.generateRecommendations() }
            await service.waitForFirstRequest()
            var newSettings = enabledSettings
            newSettings.articleCount = 3
            try await controller.saveSettings(newSettings)
            #expect(await controller.isGenerating == false)

            let nextRun = Task { try await controller.generateRecommendations() }
            service.failPendingRequests()
            _ = try? await stoppedRun.value
            _ = try? await nextRun.value

            #expect(service.requestCount > 1, "the next run made its requests")
            #expect(service.openRequestCount(whenRequestStarted: 2) == 0, "the next run started its requests after the stopped run ended")
            #expect(await controller.isGenerating == false)
        }
    }
}

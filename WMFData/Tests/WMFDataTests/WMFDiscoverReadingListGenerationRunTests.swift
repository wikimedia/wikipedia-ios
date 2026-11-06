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
}

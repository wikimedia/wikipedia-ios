import Combine
import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite(.serialized)
final class WMFDiscoverEntryCardViewModelTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }
    private let enabledSettings = WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests)

    // The card and its data controller read only these. Other suites change the environment and
    // post Discover notifications on the default center, and neither gets to the card.
    private let userDefaultsStore = WMFMockKeyValueStore()
    private let notificationCenter = NotificationCenter()
    private lazy var developerSettingsDataController = WMFDeveloperSettingsDataController(service: nil, sharedCacheStore: WMFMockKeyValueStore(), userDefaultsStore: userDefaultsStore)
    private var coreDataStore: WMFCoreDataStore?

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        await fixture.resetWMFDataTestState()
        developerSettingsDataController.enableDiscover = true
    }

    private func makeDataController(jsonResourceName: String = "related-pages-get") -> WMFDiscoverReadingListDataController {
        makeDataController(basicService: WMFMockBasicService(jsonResourceName: jsonResourceName))
    }

    /// A data controller whose generation runs until the test stops it, or until its time budget ends.
    private func makeHangingDataController(service: WMFHangingBasicService, generationTimeout: Duration = WMFDiscoverReadingListDataController.defaultGenerationTimeout) -> WMFDiscoverReadingListDataController {
        makeDataController(basicService: service, generationTimeout: generationTimeout)
    }

    private func makeDataController(basicService: WMFService, generationTimeout: Duration = WMFDiscoverReadingListDataController.defaultGenerationTimeout) -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: basicService)
        return WMFDiscoverReadingListDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore, relatedPagesDataController: relatedPagesDataController, generationTimeout: generationTimeout, notificationCenter: notificationCenter)
    }

    /// Adds to the Discover set, which the `interests` source reads. The For You set is separate.
    private func addCatInterest() async throws {
        try await WMFDiscoverInterestsDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore).addPage(title: "Cat", project: englishProject)
    }

    /// The init starts the first refresh. Wait for it with `finishRefreshAndGeneration` before the
    /// next one.
    private func makeViewModel(dataController: WMFDiscoverReadingListDataController) -> WMFDiscoverEntryCardViewModel {
        let discoverDataController = WMFDiscoverDataController(developerSettingsDataController: developerSettingsDataController)
        return WMFDiscoverEntryCardViewModel(discoverDataController: discoverDataController, readingListDataController: dataController, notificationCenter: notificationCenter)
    }

    /// Waits for the current refresh. A refresh waits for the one it cancelled, so this also covers the
    /// cancelled refreshes, and no refresh reads the stores after the fixture removes them.
    private func finishRefresh(_ viewModel: WMFDiscoverEntryCardViewModel) async {
        await viewModel.refreshTask?.value
    }

    /// Waits for the refresh in flight, for the generation it starts and for the re-read that the
    /// run's end posts. The post starts that re-read on the main actor before the run ends, and the
    /// main actor runs it before this method resumes, so the last `refreshTask` is the one to wait for.
    private func finishRefreshAndGeneration(_ viewModel: WMFDiscoverEntryCardViewModel) async {
        await finishRefresh(viewModel)
        await viewModel.generationTask?.value
        await finishRefresh(viewModel)
    }

    private func refreshAndWait(_ viewModel: WMFDiscoverEntryCardViewModel) async {
        await finishRefresh(viewModel)
        viewModel.refresh()
        await finishRefreshAndGeneration(viewModel)
    }

    /// Waits until the publisher sends a value that matches. The filter is in Combine because
    /// `values` drops the values that arrive while the loop body runs.
    private func waitUntil<StatePublisher: Publisher>(_ publisher: StatePublisher, matches isMatch: @escaping (StatePublisher.Output) -> Bool) async where StatePublisher.Failure == Never {
        for await _ in publisher.first(where: isMatch).values {}
    }

    /// Returns once the card's generating state has the given value and the re-read that set it ended.
    private func waitUntilGenerating(_ isGenerating: Bool, on viewModel: WMFDiscoverEntryCardViewModel) async {
        await waitUntil(viewModel.$isGenerating) { $0 == isGenerating }
        await finishRefresh(viewModel)
    }

    // MARK: - Visibility

    @Test
    func theCardHidesWhileDiscoverIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            developerSettingsDataController.enableDiscover = false
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isVisible == false)
        }
    }

    @Test
    func theCardHidesWhileTheReaderDidNotTurnTheListOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(dataController: makeDataController())

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isVisible == false)
        }
    }

    @Test
    func theCardHidesWhileTheListIsOnButEmpty() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isVisible == false, "like on Android, the card never opens on an empty list")
            #expect(viewModel.hasUnseenList == false)
            #expect(viewModel.collageViewModel.hasImages == false)
        }
    }

    @Test
    func theCardHidesWhenTheFirstGenerationGetsNoArticle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController(jsonResourceName: "missing-resource")
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isVisible == false)
            #expect(viewModel.isGenerating == false)
            #expect(try await dataController.fetchCurrentRecommendations().isEmpty)
        }
    }

    @Test
    func theCardKeepsTheCurrentListWhenTheNetworkFails() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let onlineDataController = makeDataController()
            try await onlineDataController.saveSettings(enabledSettings)
            let generatedPages = try await onlineDataController.generateRecommendations()
            try await onlineDataController.markCurrentListSeen()
            var changedSettings = enabledSettings
            changedSettings.articleCount = 2
            try await onlineDataController.saveSettings(changedSettings)
            let offlineDataController = makeDataController(jsonResourceName: "missing-resource")
            let viewModel = makeViewModel(dataController: offlineDataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isVisible == true)
            #expect(viewModel.hasUnseenList == false)
            #expect(viewModel.collageViewModel.hasImages == true)
            let currentPages = try await offlineDataController.fetchCurrentRecommendations()
            #expect(currentPages.map(\.title) == generatedPages.map(\.title))
        }
    }

    @Test
    func theCardShowsTheListOnceItIsGenerated() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isVisible == true)
            #expect(viewModel.collageViewModel.layout == .entryCard)
            #expect(viewModel.descriptionText.hasPrefix("Your weekly reading list."))
        }
    }

    // MARK: - Generation

    @Test
    func refreshingGeneratesTheListWhenTheCurrentOneExpired() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            _ = try await dataController.generateRecommendations()
            try await dataController.markCurrentListSeen()
            try await dataController.expireAllRecommendations()
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            let currentPages = try await dataController.fetchCurrentRecommendations()
            #expect(currentPages.isEmpty == false)
            #expect(viewModel.hasUnseenList == true)
            #expect(viewModel.collageViewModel.hasImages == true)
        }
    }

    @Test
    func refreshingKeepsTheCurrentListWhenNoneIsDue() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let generatedPages = try await dataController.generateRecommendations()
            try await dataController.markCurrentListSeen()
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            let currentPages = try await dataController.fetchCurrentRecommendations()
            #expect(currentPages.map(\.title) == generatedPages.map(\.title))
            #expect(viewModel.isVisible == true)
            #expect(viewModel.hasUnseenList == false)
        }
    }

    @Test
    func aListStateNotificationReloadsWithoutGenerating() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)
            await finishRefreshAndGeneration(viewModel)
            #expect(viewModel.collageViewModel.hasImages == true)
            try await dataController.markCurrentListSeen()
            await finishRefresh(viewModel)
            try await dataController.expireAllRecommendations()
            let isGenerationDue = try await dataController.isGenerationDue()
            #expect(isGenerationDue == true)

            // The observer starts the reload in a new task. Wait for its state, then for its end.
            notificationCenter.post(name: WMFNSNotification.discoverListStateDidChange, object: nil)
            await waitUntil(viewModel.$collageViewModel) { !$0.hasImages }
            await finishRefresh(viewModel)

            let currentPages = try await dataController.fetchCurrentRecommendations()
            #expect(currentPages.isEmpty)
            #expect(viewModel.hasUnseenList == false)
            #expect(viewModel.isGenerating == false)
            #expect(viewModel.collageViewModel.hasImages == false)
        }
    }

    /// A settings change reaches the card through the notification. The card re-reads the settings
    /// and keeps the list: the new one is made on Back from the Discover settings, not here.
    @Test
    func aSettingsChangeOnlyReReadsTheCard() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)
            await finishRefreshAndGeneration(viewModel)
            let pagesBefore = try await dataController.fetchCurrentRecommendations()
            #expect(pagesBefore.count == 3)

            var newSettings = enabledSettings
            newSettings.articleCount = 2
            try await dataController.saveSettings(newSettings)
            await waitUntil(viewModel.$settings) { $0.articleCount == 2 }
            await finishRefresh(viewModel)

            #expect(try await dataController.fetchCurrentRecommendations() == pagesBefore)
            #expect(try await dataController.isGenerationDue() == true)
            #expect(viewModel.isVisible == true)
            #expect(viewModel.isGenerating == false)
        }
    }

    // MARK: - Generating state

    @Test
    func theCardShowsTheGeneratingStateWhileARunGoesOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeHangingDataController(service: WMFHangingBasicService())
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await waitUntilGenerating(true, on: viewModel)

            #expect(viewModel.isVisible == true, "the card shows while the first list is made")
            #expect(viewModel.collageViewModel.hasImages == false)

            var newSettings = enabledSettings
            newSettings.articleCount = 2
            try await dataController.saveSettings(newSettings)
            await waitUntilGenerating(false, on: viewModel)
            await viewModel.generationTask?.value

            #expect(viewModel.isVisible == false, "the stopped run left no list")
            #expect(viewModel.settings.articleCount == 2)
        }
    }

    @Test
    func undoingTheChangeDuringTheRunBringsThePreviousListBack() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let onlineDataController = makeDataController()
            try await onlineDataController.saveSettings(enabledSettings)
            let generatedPages = try await onlineDataController.generateRecommendations()
            try await onlineDataController.markCurrentListSeen()
            var changedSettings = enabledSettings
            changedSettings.articleCount = 2
            try await onlineDataController.saveSettings(changedSettings)
            let dataController = makeHangingDataController(service: WMFHangingBasicService())
            let viewModel = makeViewModel(dataController: dataController)

            await waitUntilGenerating(true, on: viewModel)
            #expect(viewModel.isVisible == true)
            #expect(viewModel.collageViewModel.hasImages == false, "the previous list leaves the card while the new one is made")

            try await dataController.saveSettings(enabledSettings)
            await waitUntilGenerating(false, on: viewModel)
            await viewModel.generationTask?.value

            #expect(viewModel.isVisible == true)
            #expect(viewModel.hasUnseenList == false)
            #expect(viewModel.collageViewModel.hasImages == true, "the previous list comes back")
            #expect(try await dataController.fetchCurrentRecommendations() == generatedPages)
            #expect(try await dataController.isGenerationDue() == false, "the list matches the settings again")
        }
    }

    @Test
    func aRunOverTheBudgetEndsTheGeneratingStateAndKeepsTheList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let onlineDataController = makeDataController()
            try await onlineDataController.saveSettings(enabledSettings)
            let generatedPages = try await onlineDataController.generateRecommendations()
            try await onlineDataController.markCurrentListSeen()
            var changedSettings = enabledSettings
            changedSettings.articleCount = 2
            try await onlineDataController.saveSettings(changedSettings)
            let dataController = makeHangingDataController(service: WMFHangingBasicService(), generationTimeout: .milliseconds(1))
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.isGenerating == false)
            #expect(viewModel.isVisible == true)
            #expect(viewModel.hasUnseenList == false)
            #expect(viewModel.collageViewModel.hasImages == true, "the previous list comes back")
            #expect(try await dataController.fetchCurrentRecommendations() == generatedPages)
            #expect(try await dataController.isGenerationDue() == true, "the next refresh tries again")
        }
    }

    // MARK: - Unseen list

    @Test
    func aGeneratedListShowsTheDotUntilTheReaderOpensIt() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.hasUnseenList == true)

            try await dataController.markCurrentListSeen()
            await refreshAndWait(viewModel)

            #expect(viewModel.hasUnseenList == false)
        }
    }

    @Test
    func theCollageShowsTheListImagesInTwoRowsOfTwo() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            _ = try await dataController.generateRecommendations()
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefreshAndGeneration(viewModel)

            #expect(viewModel.collageViewModel.layout == .entryCard)
            #expect(viewModel.collageViewModel.tiles.count == 4)
            let collageURLs = viewModel.collageViewModel.tiles.compactMap(\.imageURL)
            #expect(collageURLs.count == 2)
            #expect(collageURLs.allSatisfy { $0.lastPathComponent.hasPrefix("960px-") })
        }
    }

    // MARK: - Byline

    @Test
    func theBylineFollowsTheUsernameProvider() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)
            await finishRefreshAndGeneration(viewModel)
            #expect(viewModel.username == nil)

            viewModel.usernameProvider = { "Reader" }
            await refreshAndWait(viewModel)

            #expect(viewModel.username == "Reader")
        }
    }

    // MARK: - Events

    @Test
    func tappingTheCardOpensTheListAndLogsIt() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)
            await finishRefreshAndGeneration(viewModel)
            let loggingDelegate = MockLoggingDelegate()
            viewModel.loggingDelegate = loggingDelegate
            var didTapCount = 0
            viewModel.didTap = { didTapCount += 1 }

            viewModel.tapCard()

            #expect(didTapCount == 1)
            #expect(loggingDelegate.tapCount == 1)
        }
    }

    @Test
    func theImpressionIsLoggedOnceWhileTheCardIsVisible() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)
            let loggingDelegate = MockLoggingDelegate()
            viewModel.loggingDelegate = loggingDelegate

            // The first refresh did not run yet, thus the card is not visible.
            viewModel.viewDidAppear()
            #expect(loggingDelegate.appearCount == 0)

            await finishRefreshAndGeneration(viewModel)
            viewModel.viewDidAppear()
            viewModel.viewDidAppear()

            #expect(loggingDelegate.appearCount == 1)
        }
    }
}

@MainActor
private final class MockLoggingDelegate: WMFDiscoverEntryCardLoggingDelegate {
    var appearCount = 0
    var tapCount = 0

    func discoverEntryCardDidAppear() {
        appearCount += 1
    }

    func discoverEntryCardDidTap() {
        tapCount += 1
    }
}

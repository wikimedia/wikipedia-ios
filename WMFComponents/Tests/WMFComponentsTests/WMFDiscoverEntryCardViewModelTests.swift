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

    // The card reads only these. Other suites change the environment and post Discover
    // notifications on the default center, and neither gets to the card.
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

    private func makeDataController() -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get"))
        return WMFDiscoverReadingListDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore, relatedPagesDataController: relatedPagesDataController)
    }

    private func addCatInterest() async throws {
        try await WMFPageInterestDataController(coreDataStore: coreDataStore).addPageInterest(title: "Cat", project: englishProject)
    }

    /// The init starts the first refresh. Wait for it with `finishRefresh` before the next one,
    /// because a cancelled refresh also runs to its end.
    private func makeViewModel(dataController: WMFDiscoverReadingListDataController) -> WMFDiscoverEntryCardViewModel {
        let discoverDataController = WMFDiscoverDataController(developerSettingsDataController: developerSettingsDataController)
        return WMFDiscoverEntryCardViewModel(discoverDataController: discoverDataController, readingListDataController: dataController, notificationCenter: notificationCenter)
    }

    /// Waits for the current refresh. Each test waits for all the refreshes it starts, thus no refresh
    /// reads the stores after the fixture removes them.
    private func finishRefresh(_ viewModel: WMFDiscoverEntryCardViewModel) async {
        await viewModel.refreshTask?.value
    }

    private func refreshAndWait(_ viewModel: WMFDiscoverEntryCardViewModel) async {
        viewModel.refresh()
        await finishRefresh(viewModel)
    }

    /// Waits until the publisher sends a value that matches. The filter is in Combine because
    /// `values` drops the values that arrive while the loop body runs.
    private func waitUntil<StatePublisher: Publisher>(_ publisher: StatePublisher, matches isMatch: @escaping (StatePublisher.Output) -> Bool) async where StatePublisher.Failure == Never {
        for await _ in publisher.first(where: isMatch).values {}
    }

    // MARK: - Visibility

    @Test
    func theCardHidesWhileDiscoverIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            developerSettingsDataController.enableDiscover = false
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefresh(viewModel)

            #expect(viewModel.isVisible == false)
        }
    }

    @Test
    func theCardHidesWhileTheReaderDidNotTurnTheListOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(dataController: makeDataController())

            await finishRefresh(viewModel)

            #expect(viewModel.isVisible == false)
        }
    }

    @Test
    func theCardShowsWithAnEmptyListOnceTheListIsOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await finishRefresh(viewModel)

            #expect(viewModel.isVisible == true)
            #expect(viewModel.hasUnseenList == false)
            #expect(viewModel.collageViewModel.hasImages == false)
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

            await finishRefresh(viewModel)

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

            await finishRefresh(viewModel)

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
            await finishRefresh(viewModel)
            #expect(viewModel.collageViewModel.hasImages == true)
            try await dataController.markCurrentListSeen()
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
            #expect(viewModel.collageViewModel.hasImages == false)
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

            await finishRefresh(viewModel)

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

            await finishRefresh(viewModel)

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
            await finishRefresh(viewModel)
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
            await finishRefresh(viewModel)
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
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)
            let loggingDelegate = MockLoggingDelegate()
            viewModel.loggingDelegate = loggingDelegate

            // The first refresh did not run yet, thus the card is not visible.
            viewModel.viewDidAppear()
            #expect(loggingDelegate.appearCount == 0)

            await finishRefresh(viewModel)
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

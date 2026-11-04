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

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        await fixture.resetWMFDataTestState()
        WMFDeveloperSettingsDataController.shared.enableDiscover = true
    }

    private func makeDataController() -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get"))
        return WMFDiscoverReadingListDataController(relatedPagesDataController: relatedPagesDataController)
    }

    private func makeViewModel(dataController: WMFDiscoverReadingListDataController) -> WMFDiscoverEntryCardViewModel {
        WMFDiscoverEntryCardViewModel(readingListDataController: dataController)
    }

    /// Waits for the refresh and for the refreshes that notifications from the data controller start.
    private func refreshAndWait(_ viewModel: WMFDiscoverEntryCardViewModel) async {
        viewModel.refresh()
        await viewModel.refreshTask?.value
        try? await Task.sleep(nanoseconds: 50_000_000)
        await viewModel.refreshTask?.value
    }

    // MARK: - Visibility

    @Test
    func theCardHidesWhileDiscoverIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDiscover = false
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await refreshAndWait(viewModel)

            #expect(viewModel.isVisible == false)
        }
    }

    @Test
    func theCardHidesWhileTheReaderDidNotTurnTheListOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(dataController: makeDataController())

            await refreshAndWait(viewModel)

            #expect(viewModel.isVisible == false)
        }
    }

    @Test
    func theCardShowsWithAnEmptyListOnceTheListIsOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            await refreshAndWait(viewModel)

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
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            _ = try await dataController.generateRecommendations()
            try await dataController.markCurrentListSeen()
            try await dataController.expireAllRecommendations()
            let viewModel = makeViewModel(dataController: dataController)

            await refreshAndWait(viewModel)

            let currentPages = try await dataController.fetchCurrentRecommendations()
            #expect(currentPages.isEmpty == false)
            #expect(viewModel.hasUnseenList == true)
            #expect(viewModel.collageViewModel.hasImages == true)
        }
    }

    @Test
    func refreshingKeepsTheCurrentListWhenNoneIsDue() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let generatedPages = try await dataController.generateRecommendations()
            try await dataController.markCurrentListSeen()
            let viewModel = makeViewModel(dataController: dataController)

            await refreshAndWait(viewModel)

            let currentPages = try await dataController.fetchCurrentRecommendations()
            #expect(currentPages.map(\.title) == generatedPages.map(\.title))
            #expect(viewModel.hasUnseenList == false)
        }
    }

    // MARK: - Unseen list

    @Test
    func aGeneratedListShowsTheDotUntilTheReaderOpensIt() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            let viewModel = makeViewModel(dataController: dataController)

            _ = try await dataController.generateRecommendations()
            await refreshAndWait(viewModel)

            #expect(viewModel.hasUnseenList == true)

            try await dataController.markCurrentListSeen()
            await refreshAndWait(viewModel)

            #expect(viewModel.hasUnseenList == false)
        }
    }

    @Test
    func theCollageShowsTheListImagesInTwoRowsOfTwo() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(enabledSettings)
            _ = try await dataController.generateRecommendations()
            let viewModel = makeViewModel(dataController: dataController)

            await refreshAndWait(viewModel)

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

            viewModel.viewDidAppear()
            #expect(loggingDelegate.appearCount == 0)

            await refreshAndWait(viewModel)
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

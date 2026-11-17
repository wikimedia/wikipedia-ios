import Combine
import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite(.serialized)
final class WMFDiscoverReadingListViewModelTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }

    // The screen and its data controller read only these. Other suites change the environment and
    // post Discover notifications on the default center, and neither gets to the screen.
    private let userDefaultsStore = WMFMockKeyValueStore()
    private let notificationCenter = NotificationCenter()
    private var coreDataStore: WMFCoreDataStore?

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    private func makeDataController(jsonResourceName: String = "related-pages-get") -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: jsonResourceName))
        return WMFDiscoverReadingListDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore, relatedPagesDataController: relatedPagesDataController, notificationCenter: notificationCenter)
    }

    /// Adds to the Discover set, which the `interests` source reads. The For You set is separate.
    private func addCatInterest() async throws {
        try await WMFDiscoverInterestsDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore).addPage(title: "Cat", project: englishProject)
    }

    private func makeViewModel(username: String? = nil, dataController: WMFDiscoverReadingListDataController) -> WMFDiscoverReadingListViewModel {
        WMFDiscoverReadingListViewModel(username: username, dataController: dataController, notificationCenter: notificationCenter)
    }

    /// Waits for the load and for the reload that its list state post starts. The post starts the
    /// reload on the main actor before the load ends, and the main actor runs it before this method
    /// resumes, so `reloadTask` is set. Each test waits for every task it starts, thus no task reads
    /// the stores after the fixture removes them.
    private func loadAndWait(_ viewModel: WMFDiscoverReadingListViewModel) async {
        viewModel.load()
        await finishTasks(of: viewModel)
    }

    /// Waits for the reload that a settings change started, then for the return from the settings screen.
    private func returnFromSettingsAndWait(_ viewModel: WMFDiscoverReadingListViewModel) async {
        await viewModel.reloadTask?.value
        viewModel.reloadIfGenerationDue()
        await finishTasks(of: viewModel)
    }

    private func finishTasks(of viewModel: WMFDiscoverReadingListViewModel) async {
        await viewModel.loadTask?.value
        await viewModel.reloadTask?.value
    }

    /// Waits until the publisher sends a value that matches. The filter is in Combine because
    /// `values` drops the values that arrive while the loop body runs.
    private func waitUntil<StatePublisher: Publisher>(_ publisher: StatePublisher, matches isMatch: @escaping (StatePublisher.Output) -> Bool) async where StatePublisher.Failure == Never {
        for await _ in publisher.first(where: isMatch).values {}
    }

    // MARK: - Loading

    @Test
    func theListIsEmptyWhenTheReaderHasNoInterests() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(dataController: makeDataController())

            await loadAndWait(viewModel)

            #expect(viewModel.state == .empty)
            #expect(viewModel.pages.isEmpty)
            #expect(viewModel.collageViewModel.tiles.allSatisfy { $0.imageURL == nil })
        }
    }

    @Test
    func theListShowsTheErrorWhenTheFirstGenerationGetsNoArticle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController(jsonResourceName: "missing-resource")
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests))
            let viewModel = makeViewModel(dataController: dataController)

            await loadAndWait(viewModel)

            #expect(viewModel.state == .error, "never the empty state: the reader has interests and can retry")
            #expect(viewModel.pages.isEmpty)
        }
    }

    @Test
    func theListKeepsTheCurrentPagesWhenTheNetworkFails() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let settings = WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests)
            let onlineDataController = makeDataController()
            try await onlineDataController.saveSettings(settings)
            let generatedPages = try await onlineDataController.generateRecommendations()
            try await onlineDataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests))
            let offlineDataController = makeDataController(jsonResourceName: "missing-resource")
            let viewModel = makeViewModel(dataController: offlineDataController)

            await loadAndWait(viewModel)

            #expect(viewModel.state == .loaded)
            #expect(viewModel.pages.map(\.title) == generatedPages.map(\.title))
        }
    }

    @Test
    func theListShowsTheRecommendedPagesAndTheirImages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let viewModel = makeViewModel(username: "Reader", dataController: makeDataController())

            await loadAndWait(viewModel)

            #expect(viewModel.state == .loaded)
            #expect(Set(viewModel.pages.map(\.title)) == ["Trap–neuter–return", "Purr", "Feral cat"])
            #expect(viewModel.articleCountText == "3 articles")

            let collageURLs = viewModel.collageViewModel.tiles.compactMap(\.imageURL)
            #expect(collageURLs.count == 2)
            #expect(collageURLs.allSatisfy { $0.lastPathComponent.hasPrefix("960px-") })
        }
    }

    @Test
    func theDescriptionFollowsTheCadence() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .daily, source: .interests))
            let viewModel = makeViewModel(dataController: dataController)

            await loadAndWait(viewModel)

            #expect(viewModel.settings.cadence == .daily)
            #expect(viewModel.descriptionText.hasPrefix("Your daily reading list."))
        }
    }

    // MARK: - Back from the settings

    @Test
    func aNewArticleCountRegeneratesTheListOnReturn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests))
            let viewModel = makeViewModel(dataController: dataController)
            await loadAndWait(viewModel)
            #expect(viewModel.pages.count == 2)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests))
            await returnFromSettingsAndWait(viewModel)

            #expect(viewModel.state == .loaded)
            #expect(viewModel.pages.count == 3)
            #expect(viewModel.settings.articleCount == 3)
        }
    }

    @Test
    func aNewCadenceOnlyRefreshesTheDescriptionOnReturn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests))
            let viewModel = makeViewModel(dataController: dataController)
            await loadAndWait(viewModel)
            let pagesBefore = viewModel.pages.map(\.title)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .daily, source: .interests))
            await returnFromSettingsAndWait(viewModel)

            #expect(viewModel.state == .loaded)
            #expect(viewModel.pages.map(\.title) == pagesBefore)
            #expect(viewModel.settings.cadence == .daily)
            #expect(viewModel.descriptionText.hasPrefix("Your daily reading list."))
        }
    }

    @Test
    func discoverOffKeepsTheListOnReturnAndTheRegenerationWaits() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests))
            let viewModel = makeViewModel(dataController: dataController)
            await loadAndWait(viewModel)
            let pagesBefore = viewModel.pages.map(\.title)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: false, articleCount: 3, cadence: .weekly, source: .interests))
            await returnFromSettingsAndWait(viewModel)

            #expect(viewModel.state == .loaded)
            #expect(viewModel.pages.map(\.title) == pagesBefore)
            #expect(viewModel.settings.isEnabled == false)
            #expect(try await dataController.isGenerationDue(), "the new article count regenerates the list when Discover is turned on again")
        }
    }

    @Test
    func theFirstLoadMarksTheOnboardingToastAsShown() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = makeDataController()
            #expect(await dataController.hasShownOnboardingToast == false)
            let viewModel = makeViewModel(dataController: dataController)

            await loadAndWait(viewModel)

            #expect(await dataController.hasShownOnboardingToast == true)
        }
    }

    @Test
    func loadingTheListMarksItAsSeen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            _ = try await dataController.generateRecommendations()
            #expect(await dataController.hasUnseenList == true)
            let viewModel = makeViewModel(dataController: dataController)

            await loadAndWait(viewModel)

            #expect(await dataController.hasUnseenList == false)
        }
    }

    @Test
    func theScreenFollowsAListGeneratedWhileItIsOpen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addCatInterest()
            let dataController = makeDataController()
            let viewModel = makeViewModel(dataController: dataController)
            await loadAndWait(viewModel)
            let firstPages = viewModel.pages
            #expect(firstPages.isEmpty == false)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests))
            await viewModel.reloadTask?.value
            let generatedPages = try await dataController.generateRecommendations()
            await waitUntil(viewModel.$pages) { $0 == generatedPages }
            await viewModel.reloadTask?.value

            #expect(viewModel.pages == generatedPages)
            #expect(viewModel.pages != firstPages)
            #expect(await dataController.hasUnseenList == false)
        }
    }
}

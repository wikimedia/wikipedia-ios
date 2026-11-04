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

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    private func makeDataController() -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get"))
        return WMFDiscoverReadingListDataController(relatedPagesDataController: relatedPagesDataController)
    }

    private func loadAndWait(_ viewModel: WMFDiscoverReadingListViewModel) async {
        viewModel.load()
        await viewModel.loadTask?.value
    }

    // MARK: - Loading

    @Test
    func theListIsEmptyWhenTheReaderHasNoInterests() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: makeDataController())

            await loadAndWait(viewModel)

            #expect(viewModel.state == .empty)
            #expect(viewModel.pages.isEmpty)
            #expect(viewModel.collageViewModel.tiles.allSatisfy { $0.imageURL == nil })
        }
    }

    @Test
    func theListShowsTheRecommendedPagesAndTheirImages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let viewModel = WMFDiscoverReadingListViewModel(username: "Reader", dataController: makeDataController())

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
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)

            await loadAndWait(viewModel)

            #expect(viewModel.settings.cadence == .daily)
            #expect(viewModel.descriptionText.hasPrefix("Your daily reading list."))
        }
    }

    // MARK: - Back from the settings

    @Test
    func aNewArticleCountRegeneratesTheListOnReturn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests))
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
            await loadAndWait(viewModel)
            #expect(viewModel.pages.count == 2)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests))
            viewModel.reloadIfGenerationDue()
            await viewModel.loadTask?.value

            #expect(viewModel.state == .loaded)
            #expect(viewModel.pages.count == 3)
            #expect(viewModel.settings.articleCount == 3)
        }
    }

    @Test
    func aNewCadenceOnlyRefreshesTheDescriptionOnReturn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests))
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
            await loadAndWait(viewModel)
            let pagesBefore = viewModel.pages.map(\.title)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .daily, source: .interests))
            viewModel.reloadIfGenerationDue()
            await viewModel.loadTask?.value

            #expect(viewModel.state == .loaded)
            #expect(viewModel.pages.map(\.title) == pagesBefore)
            #expect(viewModel.settings.cadence == .daily)
            #expect(viewModel.descriptionText.hasPrefix("Your daily reading list."))
        }
    }

    @Test
    func discoverOffKeepsTheListOnReturnAndTheRegenerationWaits() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests))
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
            await loadAndWait(viewModel)
            let pagesBefore = viewModel.pages.map(\.title)

            try await dataController.saveSettings(WMFDiscoverSettings(isEnabled: false, articleCount: 3, cadence: .weekly, source: .interests))
            viewModel.reloadIfGenerationDue()
            await viewModel.loadTask?.value

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
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)

            await loadAndWait(viewModel)

            #expect(await dataController.hasShownOnboardingToast == true)
        }
    }

    @Test
    func loadingTheListMarksItAsSeen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            _ = try await dataController.generateRecommendations()
            #expect(await dataController.hasUnseenList == true)
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)

            await loadAndWait(viewModel)

            #expect(await dataController.hasUnseenList == false)
        }
    }

    @Test
    func theScreenFollowsAListGeneratedWhileItIsOpen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFPageInterestDataController().addPageInterest(title: "Cat", project: englishProject)
            let dataController = makeDataController()
            let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
            await loadAndWait(viewModel)
            let firstPages = viewModel.pages
            #expect(firstPages.isEmpty == false)

            let generatedPages = try await dataController.generateRecommendations()
            #expect(await dataController.hasUnseenList == true)
            try? await Task.sleep(nanoseconds: 50_000_000)
            await viewModel.reloadTask?.value

            #expect(viewModel.pages == generatedPages)
            #expect(viewModel.pages != firstPages)
            #expect(await dataController.hasUnseenList == false)
        }
    }
}

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
}

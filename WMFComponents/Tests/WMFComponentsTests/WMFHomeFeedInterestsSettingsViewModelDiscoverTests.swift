import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

/// The interests screen opened from Discover: it reads and writes the Discover set, never For You.
@MainActor
@Suite(.serialized)
final class WMFHomeFeedInterestsSettingsViewModelDiscoverTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    /// A controller on its own temporary store, so a test needs no configured environment to read or write the set.
    private func makeDiscoverDataController(coreDataStore: WMFCoreDataStore? = nil) async throws -> WMFDiscoverInterestsDataController {
        let store: WMFCoreDataStore
        if let coreDataStore {
            store = coreDataStore
        } else {
            store = try await fixture.makeTemporaryCoreDataStore()
        }
        return WMFDiscoverInterestsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())
    }

    private func makeHomeDataController() -> WMFHomeDataController {
        WMFHomeDataController(basicService: WMFMockBasicService(jsonResourceName: "random-articles-get"), userDefaultsStore: WMFMockKeyValueStore())
    }

    private func makeViewModel(homeDataController: WMFHomeDataController, discoverInterestsStore: WMFDiscoverInterestsStore?) -> WMFHomeFeedInterestsSettingsViewModel {
        let searchDataController = WMFArticleSearchDataController(basicService: WMFMockBasicService(jsonResourceName: "article-prefix-search-get"))
        return WMFHomeFeedInterestsSettingsViewModel(dataController: homeDataController, discoverInterestsStore: discoverInterestsStore, searchDataController: searchDataController, project: englishProject, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
    }

    private func makeCard(_ title: String, isSelected: Bool = false) -> WMFInterestArticleCardViewModel {
        let article = WMFRandomArticle(pageid: title.hashValue, title: title, displayTitle: nil, variantTitles: nil, description: nil, extract: nil, thumbnail: nil)
        return WMFInterestArticleCardViewModel(article: article, project: englishProject, isSelected: isSelected)
    }

    private func addPageView(_ title: String, timestamp: Date) async throws {
        let pageViewsDataController = try WMFPageViewsDataController()
        _ = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: englishProject, previousPageViewObjectID: nil, timestamp: timestamp)
    }

    /// Waits for the grid to settle after the view model opens or a topic changes.
    private func waitForGrid(_ viewModel: WMFHomeFeedInterestsSettingsViewModel) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while (viewModel.isFetchingArticles || viewModel.gridViewModels.isEmpty) && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - Subtitle

    @Test
    func forYouHasNoSubtitle() {
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: nil)
        #expect(viewModel.subtitle == nil)
    }

    @Test
    func discoverShowsTheSubtitle() async throws {
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: WMFDiscoverInterestsStore(dataController: try await makeDiscoverDataController()))
        #expect(viewModel.subtitle == "Changes here only affect what you see in Discover.")
    }

    @Test
    func discoverModeOpensWithTheDiscoverTopics() async throws {
        let dataController = try await makeDiscoverDataController()
        try await dataController.setTopics([.music, .architecture])
        let store = await WMFDiscoverInterestsStore.load(dataController: dataController)

        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)

        #expect(viewModel.selectedTopics == [.music, .architecture])
    }

    @Test
    func discoverModeOpensWithTheDiscoverArticlesSelected() async throws {
        let dataController = try await makeDiscoverDataController()
        try await dataController.addPage(title: "Marie_Curie", project: englishProject)
        let store = await WMFDiscoverInterestsStore.load(dataController: dataController)

        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
        try await waitForGrid(viewModel)

        let card = viewModel.gridViewModels.first { $0.id == "Marie_Curie" }
        #expect(card?.isSelected == true)
        #expect(viewModel.selectedCount == 1)
    }

    // MARK: - Persistence

    @Test
    func discoverTapsStayOnScreenUntilTheCommit() async throws {
        let dataController = try await makeDiscoverDataController()
        let store = WMFDiscoverInterestsStore(dataController: dataController)
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)

        viewModel.toggleTopic(.music)

        #expect(store.interests.topics == [.music])
        #expect(try await dataController.fetchInterests().isEmpty, "a tap changes only the copy on screen")
    }

    @Test
    func theCommitSavesTheDiscoverTapsAndNotToForYou() async throws {
        let dataController = try await makeDiscoverDataController()
        let store = WMFDiscoverInterestsStore(dataController: dataController)
        let homeDataController = makeHomeDataController()
        let viewModel = makeViewModel(homeDataController: homeDataController, discoverInterestsStore: store)

        viewModel.toggleTopic(.music)
        let card = makeCard("Purr")
        viewModel.gridViewModels = [card]
        viewModel.toggleArticleSelection(card)
        try await store.commit()

        let saved = try await dataController.fetchInterests()
        #expect(saved.topics == [.music])
        #expect(saved.pages == [WMFDiscoverInterests.Page(title: "Purr", project: englishProject)])
        #expect(homeDataController.interestTopics().isEmpty)
    }

    @Test
    func untappingOneOfTwoArticlesRemovesItFromTheDiscoverSet() async throws {
        let dataController = try await makeDiscoverDataController()
        try await dataController.addPage(title: "Purr", project: englishProject)
        try await dataController.addPage(title: "Cat", project: englishProject)
        let store = await WMFDiscoverInterestsStore.load(dataController: dataController)
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
        try await waitForGrid(viewModel)

        let card = try #require(viewModel.gridViewModels.first { $0.id == "Purr" })
        viewModel.toggleArticleSelection(card)
        try await store.commit()

        let saved = try await dataController.fetchInterests()
        #expect(saved.pages.map(\.title) == ["Cat"])
    }

    @Test
    func untappingTheLastArticleKeepsTheSavedSet() async throws {
        let dataController = try await makeDiscoverDataController()
        try await dataController.addPage(title: "Purr", project: englishProject)
        let store = await WMFDiscoverInterestsStore.load(dataController: dataController)
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
        try await waitForGrid(viewModel)

        let card = try #require(viewModel.gridViewModels.first { $0.id == "Purr" })
        viewModel.toggleArticleSelection(card)
        try await store.commit()

        #expect(viewModel.selectedCount == 0)
        #expect(store.interests.isEmpty)
        let saved = try await dataController.fetchInterests()
        #expect(saved.pages.map(\.title) == ["Purr"], "an empty set is never committed, so Discover always has an interest to build from")
    }

    @Test
    func deselectAllKeepsTheSavedSetUntilTheNextCommitWithASelection() async throws {
        let dataController = try await makeDiscoverDataController()
        try await dataController.setTopics([.music])
        try await dataController.addPage(title: "Purr", project: englishProject)
        let store = await WMFDiscoverInterestsStore.load(dataController: dataController)
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
        try await waitForGrid(viewModel)

        viewModel.deselectAll()
        try await store.commit()
        #expect(viewModel.selectedCount == 0)
        #expect(try await dataController.fetchInterests() == WMFDiscoverInterests(topics: [.music], pages: [WMFDiscoverInterests.Page(title: "Purr", project: englishProject)]), "an empty set is never committed")

        let card = try #require(viewModel.gridViewModels.first { $0.id == "Purr" })
        viewModel.toggleArticleSelection(card)
        try await store.commit()

        let saved = try await dataController.fetchInterests()
        #expect(saved.topics.isEmpty, "the commit saves the set as it is on screen")
        #expect(saved.pages.map(\.title) == ["Purr"])
    }

    // MARK: - Grid pre-fill

    @Test
    func discoverGridShowsSelectedThenRecentHistoryThenRandom() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addPageView("Older_Read", timestamp: Date(timeIntervalSinceNow: -200))
            try await addPageView("Newer_Read", timestamp: Date(timeIntervalSinceNow: -100))
            let dataController = try await makeDiscoverDataController(coreDataStore: WMFDataEnvironment.current.coreDataStore)
            try await dataController.addPage(title: "Chosen", project: englishProject)
            let store = await WMFDiscoverInterestsStore.load(dataController: dataController)

            let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
            try await waitForGrid(viewModel)

            let ids = viewModel.gridViewModels.map { $0.id }
            #expect(Array(ids.prefix(3)) == ["Chosen", "Newer_Read", "Older_Read"])
            #expect(viewModel.gridViewModels[0].isSelected)
            #expect(!viewModel.gridViewModels[1].isSelected)
            #expect(viewModel.gridViewModels.count >= WMFHomeFeedInterestsSettingsViewModel.minimumSuggestedCards)
            #expect(viewModel.gridViewModels.count <= 25)
        }
    }

    @Test
    func discoverGridSkipsRandomArticlesWhenSuggestionsAreEnough() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            for index in 0..<WMFHomeFeedInterestsSettingsViewModel.minimumSuggestedCards {
                try await addPageView("Read_\(index)", timestamp: Date(timeIntervalSinceNow: TimeInterval(-100 - index)))
            }
            let dataController = try await makeDiscoverDataController(coreDataStore: WMFDataEnvironment.current.coreDataStore)
            let store = await WMFDiscoverInterestsStore.load(dataController: dataController)

            let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
            try await waitForGrid(viewModel)

            #expect(viewModel.gridViewModels.count == WMFHomeFeedInterestsSettingsViewModel.minimumSuggestedCards)
            #expect(viewModel.gridViewModels.allSatisfy { !$0.isSelected })
        }
    }

    @Test
    func discoverGridWithoutHistoryFallsBackToRandomArticles() async throws {
        let store = WMFDiscoverInterestsStore(dataController: try await makeDiscoverDataController())
        let viewModel = makeViewModel(homeDataController: makeHomeDataController(), discoverInterestsStore: store)
        try await waitForGrid(viewModel)

        #expect(viewModel.gridViewModels.count == 25)
    }
}

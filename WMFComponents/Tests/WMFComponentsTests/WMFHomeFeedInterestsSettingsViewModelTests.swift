import Testing
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite
struct WMFHomeFeedInterestsSettingsViewModelTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let spanishLanguage = WMFLanguage(languageCode: "es", languageVariantCode: nil)

    private func makeViewModel(store: WMFMockKeyValueStore = WMFMockKeyValueStore(),
                               searchLanguages: [WMFLanguage] = []) -> WMFHomeFeedInterestsSettingsViewModel {
        let dataController = WMFHomeDataController(userDefaultsStore: store)
        let searchDataController = WMFArticleSearchDataController(basicService: WMFMockBasicService(jsonResourceName: "article-prefix-search-get"))
        return WMFHomeFeedInterestsSettingsViewModel(dataController: dataController, searchDataController: searchDataController, project: project, searchLanguages: searchLanguages)
    }

    private func makeArticle(pageid: Int, title: String) -> WMFRandomArticle {
        WMFRandomArticle(pageid: pageid, title: title, displayTitle: nil, variantTitles: nil, description: nil, extract: nil, thumbnail: nil)
    }

    private func makeCard(pageid: Int, title: String, isSelected: Bool = false) -> WMFInterestArticleCardViewModel {
        WMFInterestArticleCardViewModel(article: makeArticle(pageid: pageid, title: title), project: project, isSelected: isSelected)
    }

    private func makeSearchResult(pageID: Int, namespace: Int, title: String) -> WMFArticleSearchResult {
        WMFArticleSearchResult(pageID: pageID, namespace: namespace, title: title, displayTitle: nil, description: nil, index: nil, thumbnail: nil)
    }

    // MARK: - Initial state

    @Test
    func selectedTopicsDefaultToEmpty() {
        let viewModel = makeViewModel()
        #expect(viewModel.selectedTopics.isEmpty)
    }

    @Test
    func allTopicsArePresentInTopicsList() {
        let viewModel = makeViewModel()
        #expect(viewModel.topics.count == WMFArticleTopic.allCases.count)
    }

    // MARK: - Toggle

    @Test
    func toggleSelectsTopic() {
        let viewModel = makeViewModel()
        viewModel.toggleTopic(.architecture)
        #expect(viewModel.selectedTopics.contains(.architecture))
    }

    @Test
    func toggleDeselectsAlreadySelectedTopic() {
        let viewModel = makeViewModel()
        viewModel.toggleTopic(.architecture)
        viewModel.toggleTopic(.architecture)
        #expect(!viewModel.selectedTopics.contains(.architecture))
    }

    @Test
    func toggleDoesNotAffectOtherTopics() {
        let viewModel = makeViewModel()
        viewModel.toggleTopic(.music)
        viewModel.toggleTopic(.architecture)
        #expect(viewModel.selectedTopics.contains(.music))
        #expect(viewModel.selectedTopics.contains(.architecture))

        viewModel.toggleTopic(.music)
        #expect(!viewModel.selectedTopics.contains(.music))
        #expect(viewModel.selectedTopics.contains(.architecture))
    }

    // MARK: - Article selection

    @Test
    func toggleArticleSelectionSelectsUnselectedCard() {
        let viewModel = makeViewModel()
        let cardVM = makeCard(pageid: 1, title: "Test")
        viewModel.toggleArticleSelection(cardVM)
        #expect(cardVM.isSelected == true)
    }

    @Test
    func toggleArticleSelectionDeselectsSelectedCard() {
        let viewModel = makeViewModel()
        let cardVM = makeCard(pageid: 1, title: "Test")
        viewModel.toggleArticleSelection(cardVM) // select
        viewModel.toggleArticleSelection(cardVM) // deselect
        #expect(cardVM.isSelected == false)
    }

    @Test
    func toggleArticleSelectionTracksMultipleArticles() {
        let viewModel = makeViewModel()
        let a = makeCard(pageid: 1, title: "A")
        let b = makeCard(pageid: 2, title: "B")
        viewModel.toggleArticleSelection(a)
        viewModel.toggleArticleSelection(b)
        viewModel.toggleArticleSelection(a) // deselect A only
        #expect(a.isSelected == false)
        #expect(b.isSelected == true)
    }

    // MARK: - Topic ordering

    @Test
    func orderedTopicsMatchDefaultOrderWithoutSelection() {
        let viewModel = makeViewModel()
        #expect(viewModel.orderedTopics == viewModel.topics)
    }

    @Test
    func orderedTopicsMoveSelectionToFrontAlphabetically() {
        let viewModel = makeViewModel()
        viewModel.toggleTopic(.education)
        #expect(viewModel.orderedTopics.first == .education)

        // A later selection that sorts earlier alphabetically goes in front
        viewModel.toggleTopic(.architecture)
        #expect(Array(viewModel.orderedTopics.prefix(2)) == [.architecture, .education])

        // Unselected topics keep their default order after the selected group
        let unselected = viewModel.orderedTopics.dropFirst(2)
        #expect(Array(unselected) == viewModel.topics.filter { $0 != .architecture && $0 != .education })
    }

    @Test
    func orderedTopicsRestoreDefaultOrderOnDeselection() {
        let viewModel = makeViewModel()
        viewModel.toggleTopic(.education)
        viewModel.toggleTopic(.education)
        #expect(viewModel.orderedTopics == viewModel.topics)
    }

    // MARK: - Selected count

    @Test
    func selectedCountCombinesTopicsAndArticles() {
        let viewModel = makeViewModel()
        viewModel.toggleTopic(.music)
        viewModel.toggleTopic(.architecture)

        let card = makeCard(pageid: 1, title: "A")
        viewModel.gridViewModels = [card]
        viewModel.toggleArticleSelection(card)

        #expect(viewModel.selectedCount == 3)
    }

    @Test
    func selectedCountIsZeroInitially() {
        let viewModel = makeViewModel()
        #expect(viewModel.selectedCount == 0)
    }

    @Test
    func deselectAllClearsTopicsAndArticles() {
        let store = WMFMockKeyValueStore()
        let viewModel = makeViewModel(store: store)
        viewModel.toggleTopic(.music)

        let card = makeCard(pageid: 1, title: "A")
        viewModel.gridViewModels = [card]
        viewModel.toggleArticleSelection(card)
        #expect(viewModel.selectedCount == 2)

        viewModel.deselectAll()
        #expect(viewModel.selectedTopics.isEmpty)
        #expect(card.isSelected == false)
        #expect(viewModel.selectedCount == 0)

        // Topics cleared in persistence too
        let dataController = WMFHomeDataController(userDefaultsStore: store)
        #expect(dataController.interestTopics().isEmpty)
    }

    // MARK: - Search

    @Test
    func addSearchResultInsertsSelectedCardAtTop() {
        let viewModel = makeViewModel()
        viewModel.gridViewModels = [makeCard(pageid: 1, title: "Existing")]

        let result = makeSearchResult(pageID: 2, namespace: 0, title: "Einstein")
        let added = viewModel.addSearchResult(result)

        #expect(added == true)
        #expect(viewModel.gridViewModels.first?.id == "Einstein")
        #expect(viewModel.gridViewModels.first?.isSelected == true)
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.hasChanges == true)
    }

    @Test
    func addSearchResultRejectsNonMainspaceArticle() {
        let viewModel = makeViewModel()
        let talkPage = makeSearchResult(pageID: 3, namespace: 1, title: "Talk:Einstein")
        let added = viewModel.addSearchResult(talkPage)

        #expect(added == false)
        #expect(viewModel.gridViewModels.isEmpty)
        #expect(viewModel.selectedCount == 0)
    }

    @Test
    func addSearchResultSelectsExistingCardInsteadOfDuplicating() {
        let viewModel = makeViewModel()
        let existing = makeCard(pageid: 1, title: "Einstein")
        viewModel.gridViewModels = [existing]

        let result = makeSearchResult(pageID: 1, namespace: 0, title: "Einstein")
        viewModel.addSearchResult(result)

        #expect(viewModel.gridViewModels.count == 1)
        #expect(existing.isSelected == true)
    }

    @Test
    func addSearchResultClearsSearchTerm() {
        let viewModel = makeViewModel()
        viewModel.searchTerm = "Einst"
        viewModel.addSearchResult(makeSearchResult(pageID: 2, namespace: 0, title: "Einstein"))
        #expect(viewModel.searchTerm.isEmpty)
        #expect(viewModel.isSearchActive == false)
    }

    @Test
    func searchUsesSelectedSearchLanguage() {
        let viewModel = makeViewModel(searchLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil), spanishLanguage])
        #expect(viewModel.searchLanguage.languageCode == "en")

        viewModel.selectSearchLanguage(spanishLanguage)
        #expect(viewModel.searchLanguage.languageCode == "es")

        let added = viewModel.addSearchResult(makeSearchResult(pageID: 4, namespace: 0, title: "Einstein"))
        #expect(added == true)
        #expect(viewModel.gridViewModels.first?.project == .wikipedia(spanishLanguage))
    }

    @Test
    func searchLanguagesFallBackToProjectLanguage() {
        let viewModel = makeViewModel()
        #expect(viewModel.searchLanguages.count == 1)
        #expect(viewModel.searchLanguages.first?.languageCode == "en")
    }

    @Test
    func updateProjectFollowsPrimaryLanguageChange() {
        let viewModel = makeViewModel()
        let spanishProject = WMFProject.wikipedia(spanishLanguage)
        viewModel.updateProject(spanishProject)
        #expect(viewModel.project == spanishProject)
    }

    @Test
    func updateProjectMovesSearchLanguageToNewPrimaryEvenWhenOldRemains() {
        // Reordering to change the primary keeps both languages available, so the search
        // language must still follow the new primary.
        let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let viewModel = makeViewModel(searchLanguages: [english, spanishLanguage])
        #expect(viewModel.searchLanguage == english)

        viewModel.updateSearchLanguages([spanishLanguage, english])
        viewModel.updateProject(.wikipedia(spanishLanguage))
        #expect(viewModel.searchLanguage == spanishLanguage)
    }

    @Test
    func updateSearchLanguagesResetsInvalidSelection() {
        let viewModel = makeViewModel(searchLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil), spanishLanguage])
        viewModel.selectSearchLanguage(spanishLanguage)

        viewModel.updateSearchLanguages([WMFLanguage(languageCode: "fr", languageVariantCode: nil)])
        #expect(viewModel.searchLanguage.languageCode == "fr")
        #expect(viewModel.searchLanguages.count == 1)
    }

    @Test
    func searchTermDrivesSearchRows() async throws {
        let viewModel = makeViewModel()
        viewModel.searchTerm = "einstein"
        #expect(viewModel.isSearching == true)

        // Wait out the debounce and the mocked fetch; polling keeps this fast locally while
        // tolerating slow CI runners (a fixed sleep flaked there).
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while (viewModel.searchRows.count != 4 || viewModel.isSearching) && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(viewModel.searchRows.count == 4)
        #expect(viewModel.isSearching == false)

        viewModel.clearSearch()
        #expect(viewModel.searchRows.isEmpty)
    }

    // MARK: - Grid cap

    @Test
    func buildGridCapsArticlesAt25() async throws {
        let viewModel = makeViewModel()
        let selected = makeCard(pageid: 999, title: "Saved", isSelected: true)
        viewModel.gridViewModels = [selected]

        let articles = (1...40).map { makeArticle(pageid: $0, title: "Article \($0)") }
        viewModel.buildGrid(from: articles)

        #expect(viewModel.gridViewModels.count == 25)
        #expect(viewModel.gridViewModels.first?.id == "Saved")
    }

    // MARK: - Persistence

    @Test
    func unknownRawValuesAreIgnoredOnLoad() {
        let store = WMFMockKeyValueStore()
        // Write raw strings directly to the store to simulate a stale/unknown topic ID
        try? store.save(key: "home-feed-interest-topics", value: ["architecture", "not-a-real-topic"])

        let dataController = WMFHomeDataController(userDefaultsStore: store)
        let viewModel = WMFHomeFeedInterestsSettingsViewModel(dataController: dataController, project: project)
        #expect(viewModel.selectedTopics == [.architecture])
    }
}

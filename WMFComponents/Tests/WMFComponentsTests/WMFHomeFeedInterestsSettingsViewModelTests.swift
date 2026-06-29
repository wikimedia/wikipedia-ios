import Testing
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite
struct WMFHomeFeedInterestsSettingsViewModelTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeViewModel(store: WMFMockKeyValueStore = WMFMockKeyValueStore()) -> WMFHomeFeedInterestsSettingsViewModel {
        let dataController = WMFHomeDataController(userDefaultsStore: store)
        return WMFHomeFeedInterestsSettingsViewModel(dataController: dataController, project: project)
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
        let article = WMFRandomArticle(pageid: 1, title: "Test", displayTitle: nil, variantTitles: nil, description: nil, extract: nil, thumbnail: nil)
        let cardVM = WMFInterestArticleCardViewModel(article: article)
        viewModel.toggleArticleSelection(cardVM)
        #expect(cardVM.isSelected == true)
    }

    @Test
    func toggleArticleSelectionDeselectsSelectedCard() {
        let viewModel = makeViewModel()
        let article = WMFRandomArticle(pageid: 1, title: "Test", displayTitle: nil, variantTitles: nil, description: nil, extract: nil, thumbnail: nil)
        let cardVM = WMFInterestArticleCardViewModel(article: article)
        viewModel.toggleArticleSelection(cardVM) // select
        viewModel.toggleArticleSelection(cardVM) // deselect
        #expect(cardVM.isSelected == false)
    }

    @Test
    func toggleArticleSelectionTracksMultipleArticles() {
        let viewModel = makeViewModel()
        let a = WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 1, title: "A", displayTitle: nil, variantTitles: nil, description: nil, extract: nil, thumbnail: nil))
        let b = WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 2, title: "B", displayTitle: nil, variantTitles: nil, description: nil, extract: nil, thumbnail: nil))
        viewModel.toggleArticleSelection(a)
        viewModel.toggleArticleSelection(b)
        viewModel.toggleArticleSelection(a) // deselect A only
        #expect(a.isSelected == false)
        #expect(b.isSelected == true)
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

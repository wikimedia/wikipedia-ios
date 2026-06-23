import Testing
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite
struct WMFHomeFeedInterestsSettingsViewModelTests {

    private func makeViewModel(store: WMFMockKeyValueStore = WMFMockKeyValueStore()) -> WMFHomeFeedInterestsSettingsViewModel {
        let dataController = WMFHomeDataController(userDefaultsStore: store)
        return WMFHomeFeedInterestsSettingsViewModel(dataController: dataController)
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

    @Test
    func unknownRawValuesAreIgnoredOnLoad() {
        let store = WMFMockKeyValueStore()
        let dataController = WMFHomeDataController(userDefaultsStore: store)
        dataController.setInterestTopicIDs(["architecture", "not-a-real-topic"])

        let viewModel = WMFHomeFeedInterestsSettingsViewModel(dataController: dataController)
        #expect(viewModel.selectedTopics == [.architecture])
    }
}

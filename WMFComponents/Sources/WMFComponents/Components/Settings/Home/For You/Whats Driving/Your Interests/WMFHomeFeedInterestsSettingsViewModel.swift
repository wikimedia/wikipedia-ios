import Foundation
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedInterestsSettingsViewModel: ObservableObject {

    let title = WMFLocalizedString("home-feed-interests-settings-title", value: "Your interests", comment: "Navigation bar title for the Your interests settings screen.")
    let emptyMessage = WMFLocalizedString("home-feed-interests-settings-empty-message", value: "Your interests will show here", comment: "Message shown on the Your interests screen when there are no interests to display yet.")

    let topics: [WMFArticleTopic] = WMFArticleTopic.allCases
    @Published var selectedTopics: Set<WMFArticleTopic> = []

    private let dataController: WMFHomeDataController

    public init(dataController: WMFHomeDataController = WMFHomeDataController.shared) {
        self.dataController = dataController
        let savedIDs = dataController.interestTopicIDs()
        self.selectedTopics = Set(savedIDs.compactMap { WMFArticleTopic(rawValue: $0) })
    }

    func toggleTopic(_ topic: WMFArticleTopic) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
        dataController.setInterestTopicIDs(selectedTopics.map { $0.rawValue })
    }
}

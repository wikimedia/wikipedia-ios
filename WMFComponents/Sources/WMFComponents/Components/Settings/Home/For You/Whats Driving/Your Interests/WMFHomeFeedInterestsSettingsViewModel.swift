import Foundation
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedInterestsSettingsViewModel: ObservableObject {

    let title = WMFLocalizedString("home-feed-interests-settings-title", value: "Your interests", comment: "Navigation bar title for the Your interests settings screen.")
    let emptyMessage = WMFLocalizedString("home-feed-interests-settings-empty-message", value: "Your interests will show here", comment: "Message shown on the Your interests screen when there are no interests to display yet.")

    let topics: [WMFArticleTopic] = WMFArticleTopic.allCases
    @Published var selectedTopics: [WMFArticleTopic] = []
    @Published var randomArticles: [WMFRandomArticle] = []
    @Published var isFetchingArticles: Bool = false

    private let dataController: WMFHomeDataController
    private let project: WMFProject
    private var fetchTask: Task<Void, Never>?

    public init(dataController: WMFHomeDataController = WMFHomeDataController.shared, project: WMFProject) {
        self.dataController = dataController
        self.project = project
        self.selectedTopics = dataController.interestTopics()

        if selectedTopics.isEmpty {
            fetchRandomArticles()
        } else if let topic = selectedTopics.last {
            fetchArticles(for: topic)
        }
    }

    func toggleTopic(_ topic: WMFArticleTopic) {
        if let index = selectedTopics.firstIndex(of: topic) {
            selectedTopics.remove(at: index)
        } else {
            selectedTopics.append(topic)
        }
        dataController.setInterestTopics(selectedTopics)

        if selectedTopics.isEmpty {
            fetchRandomArticles()
        } else if let topic = selectedTopics.last {
            fetchArticles(for: topic)
        }
    }

    func fetchRandomArticles() {
        fetchTask?.cancel()
        isFetchingArticles = true
        fetchTask = Task {
            do {
                let articles = try await dataController.fetchRandomArticles(project: project)
                guard !Task.isCancelled else { return }
                self.randomArticles = articles
            } catch {
                // TODO: Error state
            }
            self.isFetchingArticles = false
        }
    }

    func fetchArticles(for topic: WMFArticleTopic) {
        fetchTask?.cancel()
        isFetchingArticles = true
        fetchTask = Task {
            do {
                let articles = try await dataController.fetchArticles(for: topic, project: project)
                guard !Task.isCancelled else { return }
                self.randomArticles = articles
            } catch {
                // TODO: Error state
            }
            self.isFetchingArticles = false
        }
    }

    deinit {
        fetchTask?.cancel()
    }
}

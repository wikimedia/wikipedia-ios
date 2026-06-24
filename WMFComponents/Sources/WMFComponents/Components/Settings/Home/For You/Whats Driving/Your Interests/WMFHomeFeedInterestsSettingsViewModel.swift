import Foundation
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedInterestsSettingsViewModel: ObservableObject {

    let title = WMFLocalizedString("home-feed-interests-settings-title", value: "Your interests", comment: "Navigation bar title for the Your interests settings screen.")
    let emptyMessage = WMFLocalizedString("home-feed-interests-settings-empty-message", value: "Your interests will show here", comment: "Message shown on the Your interests screen when there are no interests to display yet.")

    let topics: [WMFArticleTopic] = WMFArticleTopic.allCases
    @Published var selectedTopics: [WMFArticleTopic] = []
    @Published var gridViewModels: [WMFInterestArticleCardViewModel] = []
    @Published var isFetchingArticles: Bool = false

    private let dataController: WMFHomeDataController
    private let pageInterestDataController: WMFPageInterestDataController?
    private let project: WMFProject
    private var fetchTask: Task<Void, Never>?

    // Saved CDPageInterest records — kept in sync with toggles so buildGrid always has current state
    private var savedInterests: [WMFPageInterest] = []
    private var savedIDs: Set<String> = []

    public init(dataController: WMFHomeDataController = WMFHomeDataController.shared,
                pageInterestDataController: WMFPageInterestDataController? = try? WMFPageInterestDataController(),
                project: WMFProject) {
        self.dataController = dataController
        self.pageInterestDataController = pageInterestDataController
        self.project = project
        self.selectedTopics = dataController.interestTopics()

        Task {
            await loadSavedInterests()
            if self.selectedTopics.isEmpty {
                self.fetchRandomArticles()
            } else if let topic = self.selectedTopics.last {
                self.fetchArticles(for: topic)
            }
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

    /// Toggles the saved state of an article card in-place (no grid reorder).
    /// Saved articles float to the top only when the article list next reloads.
    func toggleArticleSelection(_ vm: WMFInterestArticleCardViewModel) {
        if vm.isSelected {
            vm.isSelected = false
            savedIDs.remove(vm.id)
            savedInterests.removeAll { $0.title.normalizedForCoreData == vm.id }
            Task { try? await pageInterestDataController?.removePageInterest(title: vm.rawTitle, project: project) }
        } else {
            vm.isSelected = true
            savedIDs.insert(vm.id)
            let interest = WMFPageInterest(title: vm.rawTitle, projectID: project.id, timestamp: Date())
            savedInterests.insert(interest, at: 0)
            Task { try? await pageInterestDataController?.addPageInterest(title: vm.rawTitle, project: project) }
        }
    }

    // MARK: - Private

    private func loadSavedInterests() async {
        let interests = (try? await pageInterestDataController?.fetchPageInterests(project: project)) ?? []
        savedInterests = interests
        savedIDs = Set(interests.map { $0.title.normalizedForCoreData })
    }

    /// Rebuilds gridViewModels: saved interests at top (selected), then the given random/topic articles.
    /// Only called when the article list reloads — not on individual card selection.
    private func buildGrid(from articles: [WMFRandomArticle]) {
        let savedVMs = savedInterests.map { WMFInterestArticleCardViewModel(pageInterest: $0, project: project) }
        let randomVMs = articles
            .filter { !savedIDs.contains($0.title.normalizedForCoreData) }
            .map { WMFInterestArticleCardViewModel(article: $0) }
        gridViewModels = savedVMs + randomVMs
    }

    func fetchRandomArticles() {
        fetchTask?.cancel()
        isFetchingArticles = true
        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let articles = try await dataController.fetchRandomArticles(project: project)
                guard !Task.isCancelled else { return }
                self.buildGrid(from: articles)
            } catch {
                // TODO: Error state
            }
            self.isFetchingArticles = false
        }
    }

    func fetchArticles(for topic: WMFArticleTopic) {
        fetchTask?.cancel()
        isFetchingArticles = true
        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let articles = try await dataController.fetchArticles(for: topic, project: project)
                guard !Task.isCancelled else { return }
                self.buildGrid(from: articles)
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

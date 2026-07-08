import Foundation
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedInterestsSettingsViewModel: ObservableObject {

    let title = WMFLocalizedString("home-feed-interests-settings-title", value: "Your interests", comment: "Navigation bar title for the Your interests settings screen.")
    let emptyMessage = WMFLocalizedString("home-feed-interests-settings-empty-message", value: "Your interests will show here", comment: "Message shown on the Your interests screen when there are no interests to display yet.")

    let topics: [WMFArticleTopic] = WMFArticleTopic.allCases
    @Published var selectedTopics: [WMFArticleTopic] = []
    public private(set) var hasChanges: Bool = false
    @Published var gridViewModels: [WMFInterestArticleCardViewModel] = []
    @Published var isFetchingArticles: Bool = false

    private let dataController: WMFHomeDataController
    private let pageInterestDataController: WMFPageInterestDataController?
    private let project: WMFProject
    private var fetchTask: Task<Void, Never>?

    public init(dataController: WMFHomeDataController = WMFHomeDataController.shared,
                pageInterestDataController: WMFPageInterestDataController? = try? WMFPageInterestDataController(),
                project: WMFProject) {
        self.dataController = dataController
        self.pageInterestDataController = pageInterestDataController
        self.project = project
        self.selectedTopics = dataController.interestTopics()

        Task { [weak self] in
            guard let self else { return }
            await loadSavedInterests()
            if selectedTopics.isEmpty {
                fetchRandomArticles()
            } else if let topic = selectedTopics.last {
                fetchArticles(for: topic)
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
        hasChanges = true

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
            Task { try? await pageInterestDataController?.removePageInterest(title: vm.title, project: project) }
        } else {
            vm.isSelected = true
            Task { try? await pageInterestDataController?.addPageInterest(title: vm.title, project: project) }
        }
        hasChanges = true
    }

    // MARK: - Private

    private func loadSavedInterests() async {
        let interests = (try? await pageInterestDataController?.fetchPageInterests(project: project)) ?? []
        gridViewModels = interests.map { WMFInterestArticleCardViewModel(pageInterest: $0, project: project) }
    }

    /// Rebuilds gridViewModels: currently selected VMs at top, then new random/topic articles.
    /// Only called when the article list reloads — not on individual card selection.
    private func buildGrid(from articles: [WMFRandomArticle]) {
        let savedVMs = gridViewModels.filter { $0.isSelected }
        let savedIDs = Set(savedVMs.map { $0.id })
        let randomVMs = articles
            .filter { !savedIDs.contains($0.title) }
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

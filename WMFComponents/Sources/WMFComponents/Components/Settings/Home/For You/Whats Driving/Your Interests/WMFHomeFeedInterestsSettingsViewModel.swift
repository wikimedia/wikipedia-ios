import Foundation
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedInterestsSettingsViewModel: ObservableObject {

    struct SearchRow: Identifiable {
        let id: Int
        let result: WMFArticleSearchResult
        let card: WMFInterestArticleCardViewModel
    }

    let title = WMFLocalizedString("home-feed-interests-settings-title", value: "Your interests", comment: "Navigation bar title for the Your interests settings screen.")
    let emptyMessage = WMFLocalizedString("home-feed-interests-settings-empty-message", value: "Your interests will show here", comment: "Message shown on the Your interests screen when there are no interests to display yet.")
    let headerTitle = WMFLocalizedString("home-feed-interests-header-title", value: "What are you interested in?", comment: "Header title on the interests selection screen, shown before any topics or articles are selected.")
    let deselectAllTitle = WMFLocalizedString("home-feed-interests-deselect-all", value: "Deselect all", comment: "Title of the button on the interests selection screen that clears all selected topics and articles.")
    let searchPlaceholder = WMFLocalizedString("home-feed-interests-search-placeholder", value: "Search for an article", comment: "Placeholder text of the article search bar on the interests selection screen.")
    let cancelTitle = CommonStrings.cancelActionTitle
    private let selectedCountFormat = WMFLocalizedString("home-feed-interests-selected-count", value: "{{PLURAL:%1$d|%1$d selected|%1$d selected}}", comment: "Header title on the interests selection screen indicating the number of selected topics and articles. %1$d is replaced with the number of selections.")
    private let nonMainspaceToast = WMFLocalizedString("home-feed-interests-non-mainspace-toast", value: "Only articles in the main namespace can be added as interests.", comment: "Toast error message shown when a user tries to add a non-article page (e.g. a talk page) as an interest.")

    let topics: [WMFArticleTopic] = WMFArticleTopic.allCases
    @Published var selectedTopics: [WMFArticleTopic] = []
    public private(set) var hasChanges: Bool = false
    @Published var gridViewModels: [WMFInterestArticleCardViewModel] = []
    @Published var isFetchingArticles: Bool = false
    @Published private(set) var selectedArticleCount: Int = 0

    @Published var searchTerm: String = "" {
        didSet {
            guard searchTerm != oldValue else { return }
            scheduleSearch()
        }
    }
    @Published private(set) var searchRows: [SearchRow] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var searchLanguage: WMFLanguage
    @Published public private(set) var searchLanguages: [WMFLanguage]

    private let dataController: WMFHomeDataController
    private let injectedPageInterestDataController: WMFPageInterestDataController?
    private var resolvedPageInterestDataController: WMFPageInterestDataController?
    private let searchDataController: WMFArticleSearchDataController
    private(set) var project: WMFProject
    private var fetchTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    private static let maxGridArticles = 25

    /// Resolved lazily: the Core Data store may not be ready when this view model is created
    /// early in app launch (e.g. the onboarding coordinator builds it up front). Re-attempting
    /// on each access until it succeeds means selections persist once the store is available,
    /// rather than being silently dropped by a nil controller captured at init time.
    private var pageInterestDataController: WMFPageInterestDataController? {
        if let injectedPageInterestDataController {
            return injectedPageInterestDataController
        }
        if let resolvedPageInterestDataController {
            return resolvedPageInterestDataController
        }
        let controller = try? WMFPageInterestDataController()
        resolvedPageInterestDataController = controller
        return controller
    }

    public init(dataController: WMFHomeDataController = WMFHomeDataController.shared,
                pageInterestDataController: WMFPageInterestDataController? = nil,
                searchDataController: WMFArticleSearchDataController = WMFArticleSearchDataController.shared,
                project: WMFProject,
                searchLanguages: [WMFLanguage] = []) {
        self.dataController = dataController
        self.injectedPageInterestDataController = pageInterestDataController
        self.searchDataController = searchDataController
        self.project = project

        var projectLanguage: WMFLanguage?
        if case .wikipedia(let language) = project {
            projectLanguage = language
        }
        let fallbackLanguage = projectLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let resolvedSearchLanguages = searchLanguages.isEmpty ? [fallbackLanguage] : searchLanguages
        self.searchLanguages = resolvedSearchLanguages
        self.searchLanguage = resolvedSearchLanguages.first(where: { $0 == projectLanguage }) ?? resolvedSearchLanguages[0]

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

    /// Topics as displayed in the chips row: selected topics first (alphabetical by display
    /// name), followed by the unselected topics in their default order.
    var orderedTopics: [WMFArticleTopic] {
        let selected = topics
            .filter { selectedTopics.contains($0) }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        let unselected = topics.filter { !selectedTopics.contains($0) }
        return selected + unselected
    }

    var selectedCount: Int {
        return selectedTopics.count + selectedArticleCount
    }

    var selectedCountTitle: String {
        return String.localizedStringWithFormat(selectedCountFormat, selectedCount)
    }

    var isSearchActive: Bool {
        return !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        let cardProject = vm.project
        if vm.isSelected {
            vm.isSelected = false
            Task { try? await pageInterestDataController?.removePageInterest(title: vm.title, project: cardProject) }
        } else {
            vm.isSelected = true
            Task { try? await pageInterestDataController?.addPageInterest(title: vm.title, project: cardProject) }
        }
        recountSelectedArticles()
        hasChanges = true
    }

    /// Clears all selected topics and articles, then reloads the grid with random articles.
    func deselectAll() {
        selectedTopics = []
        dataController.setInterestTopics([])

        for card in gridViewModels where card.isSelected {
            card.isSelected = false
            let cardProject = card.project
            let cardTitle = card.title
            Task { try? await pageInterestDataController?.removePageInterest(title: cardTitle, project: cardProject) }
        }
        recountSelectedArticles()
        hasChanges = true
        fetchRandomArticles()
    }

    // MARK: - Search

    func selectSearchLanguage(_ language: WMFLanguage) {
        guard language != searchLanguage else { return }
        searchLanguage = language
        scheduleSearch(debounce: false)
    }

    public func updateSearchLanguages(_ languages: [WMFLanguage]) {
        guard !languages.isEmpty else { return }
        searchLanguages = languages
        if !languages.contains(searchLanguage) {
            searchLanguage = languages[0]
        }
    }

    /// Called when the user changes their primary app language during onboarding — topic and
    /// article suggestions refetch for the new language, and the search language follows the new
    /// primary. Selected cards keep their own project.
    public func updateProject(_ newProject: WMFProject) {
        guard newProject != project else { return }
        project = newProject

        // Follow the new primary for the default search language. Reordering to change the
        // primary keeps the old language in the list, so updateSearchLanguages alone wouldn't
        // move the selection off it.
        if case .wikipedia(let language) = newProject {
            searchLanguage = language
        }

        if selectedTopics.isEmpty {
            fetchRandomArticles()
        } else if let topic = selectedTopics.last {
            fetchArticles(for: topic)
        }
    }

    /// Adds a searched article to the selected interests.
    /// Returns false (and shows an error toast) when the result is not a mainspace article.
    @discardableResult
    func addSearchResult(_ result: WMFArticleSearchResult) -> Bool {
        guard result.isMainNamespace else {
            WMFToastPresenter.shared.show(WMFToastConfig(title: nonMainspaceToast))
            return false
        }

        let resultProject = WMFProject.wikipedia(searchLanguage)
        let card = WMFInterestArticleCardViewModel(searchResult: result, project: resultProject, isSelected: true)
        if let existing = gridViewModels.first(where: { $0.id == card.id }) {
            if !existing.isSelected {
                toggleArticleSelection(existing)
            }
        } else {
            gridViewModels.insert(card, at: 0)
            let cardTitle = card.title
            Task { try? await pageInterestDataController?.addPageInterest(title: cardTitle, project: resultProject) }
        }
        recountSelectedArticles()
        hasChanges = true
        clearSearch()
        return true
    }

    func clearSearch() {
        searchTask?.cancel()
        searchTerm = ""
        searchRows = []
        isSearching = false
    }

    private func scheduleSearch(debounce: Bool = true) {
        searchTask?.cancel()

        guard isSearchActive else {
            searchRows = []
            isSearching = false
            return
        }

        let term = searchTerm
        let language = searchLanguage
        isSearching = true
        searchTask = Task { [weak self] in
            if debounce {
                try? await Task.sleep(for: .milliseconds(250))
            }
            guard !Task.isCancelled, let self else { return }
            do {
                let results = try await searchDataController.search(term: term, project: .wikipedia(language))
                guard !Task.isCancelled else { return }
                self.searchRows = results.map { result in
                    let alreadySelected = self.gridViewModels.contains { $0.id == result.title && $0.isSelected }
                    let card = WMFInterestArticleCardViewModel(searchResult: result, project: .wikipedia(language), isSelected: alreadySelected)
                    return SearchRow(id: result.pageID, result: result, card: card)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.searchRows = []
            }
            self.isSearching = false
        }
    }

    // MARK: - Private

    private func recountSelectedArticles() {
        selectedArticleCount = gridViewModels.filter { $0.isSelected }.count
    }

    private func loadSavedInterests() async {
        var projects: [WMFProject] = [project]
        for language in searchLanguages {
            let languageProject = WMFProject.wikipedia(language)
            if !projects.contains(languageProject) {
                projects.append(languageProject)
            }
        }

        var cards: [WMFInterestArticleCardViewModel] = []
        var seenIDs = Set<String>()
        for interestsProject in projects {
            let interests = (try? await pageInterestDataController?.fetchPageInterests(project: interestsProject)) ?? []
            for interest in interests where !seenIDs.contains(interest.title) {
                seenIDs.insert(interest.title)
                cards.append(WMFInterestArticleCardViewModel(pageInterest: interest, project: interestsProject))
            }
        }
        gridViewModels = cards
        recountSelectedArticles()
    }

    /// Rebuilds gridViewModels: currently selected VMs at top, then new random/topic articles, capped at maxGridArticles.
    /// Only called when the article list reloads — not on individual card selection.
    func buildGrid(from articles: [WMFRandomArticle]) {
        let savedVMs = gridViewModels.filter { $0.isSelected }
        let savedIDs = Set(savedVMs.map { $0.id })
        let remainingSlots = max(0, Self.maxGridArticles - savedVMs.count)
        let randomVMs = articles
            .filter { !savedIDs.contains($0.title) }
            .prefix(remainingSlots)
            .map { WMFInterestArticleCardViewModel(article: $0, project: project) }
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
        searchTask?.cancel()
    }
}

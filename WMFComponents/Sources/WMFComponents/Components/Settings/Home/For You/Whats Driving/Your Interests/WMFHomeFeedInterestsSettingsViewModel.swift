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
    private let selectedCountFormat = WMFLocalizedString("home-feed-interests-selected-count", value: "{{PLURAL:%1$d|%1$d selected|%1$d selected}}", comment: "Header title on the interests selection screen indicating the number of selected topics and articles. %1$d is replaced with the number of selections.")
    private let nonMainspaceToast = WMFLocalizedString("home-feed-interests-non-mainspace-toast", value: "Only articles in the main namespace can be added as interests.", comment: "Toast error message shown when a user tries to add a non-article page (e.g. a talk page) as an interest.")

    let topics: [WMFArticleTopic] = WMFArticleTopic.allCases
    @Published var selectedTopics: [WMFArticleTopic] = []
    public private(set) var hasChanges: Bool = false

    var onSelectionChanged: ((_ topics: [WMFArticleTopic], _ selectedArticleTitles: [String]) -> Void)?

    private func noteChanges() {
        hasChanges = true
        let titles = gridViewModels.filter { $0.isSelected }.map { $0.title.normalizedForCoreData }
        onSelectionChanged?(selectedTopics, titles)
    }
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
    private let interestsStore: WMFInterestsStore
    private let searchDataController: WMFArticleSearchDataController
    private(set) var project: WMFProject
    private var fetchTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    private static let maxGridArticles = 25
    static let minimumSuggestedCards = 6

    // MARK: - App-side actions
    let logImpressionIfNeeded: (() -> Void)?
    let logDidTapTopic: () -> Void
    let logDidTapArticle: () -> Void
    let logDidTapDeselectAll: () -> Void

    /// Pass `discoverInterestsStore` to edit the Discover interests. Without it the screen edits
    /// the For You interests through `dataController` and `pageInterestDataController`.
    public init(dataController: WMFHomeDataController = WMFHomeDataController.shared,
                pageInterestDataController: WMFPageInterestDataController? = nil,
                discoverInterestsStore: WMFDiscoverInterestsStore? = nil,
                searchDataController: WMFArticleSearchDataController = WMFArticleSearchDataController.shared,
                project: WMFProject,
                searchLanguages: [WMFLanguage] = [],
                logImpressionIfNeeded: (() -> Void)? = nil,
                logDidTapTopic: @escaping () -> Void,
                logDidTapArticle: @escaping () -> Void,
                logDidTapDeselectAll: @escaping () -> Void) {
        self.dataController = dataController
        self.interestsStore = discoverInterestsStore ?? WMFForYouInterestsStore(homeDataController: dataController, pageInterestDataController: pageInterestDataController)
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

        self.selectedTopics = interestsStore.loadTopics()

        self.logImpressionIfNeeded = logImpressionIfNeeded
        self.logDidTapTopic = logDidTapTopic
        self.logDidTapArticle = logDidTapArticle
        self.logDidTapDeselectAll = logDidTapDeselectAll

        Task { [weak self] in
            guard let self else { return }
            await loadSavedInterests()
            reloadGrid()
        }
    }

    var subtitle: String? {
        interestsStore.subtitle
    }

    /// Called by the view controller when the reader leaves the screen for good.
    public func didLeave() {
        interestsStore.didLeave(hasChanges: hasChanges)
    }

    /// Topics as displayed in the chips row: selected topics first, in the order they were
    /// selected (Apple Maps style — a newly selected topic lands after previously selected
    /// ones), followed by the unselected topics in their default order.
    var orderedTopics: [WMFArticleTopic] {
        let unselected = topics.filter { !selectedTopics.contains($0) }
        return selectedTopics + unselected
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
        logDidTapTopic()
        if let index = selectedTopics.firstIndex(of: topic) {
            selectedTopics.remove(at: index)
        } else {
            selectedTopics.append(topic)
        }
        interestsStore.setTopics(selectedTopics)
        noteChanges()
        reloadGrid()
    }

    /// Toggles the saved state of an article card in-place (no grid reorder).
    /// Saved articles float to the top only when the article list next reloads.
    func toggleArticleSelection(_ vm: WMFInterestArticleCardViewModel) {
        logDidTapArticle()
        if vm.isSelected {
            vm.isSelected = false
            interestsStore.removePage(title: vm.title, project: vm.project)
        } else {
            vm.isSelected = true
            interestsStore.addPage(title: vm.title, project: vm.project)
        }
        recountSelectedArticles()
        noteChanges()
    }

    /// Clears all selected topics and articles, unchecking the cards in place. Deliberately
    /// does not refetch: reloading the grid here read as the whole screen changing under the
    /// user. The articles on screen stay until the list next reloads (e.g. a topic is tapped).
    func deselectAll() {
        logDidTapDeselectAll()
        selectedTopics = []
        interestsStore.setTopics([])

        for card in gridViewModels where card.isSelected {
            card.isSelected = false
            interestsStore.removePage(title: card.title, project: card.project)
        }
        recountSelectedArticles()
        noteChanges()
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

        reloadGrid()
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
            interestsStore.addPage(title: card.title, project: resultProject)
        }
        recountSelectedArticles()
        noteChanges()
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
                    let resultProject = WMFProject.wikipedia(language)
                    let resultID = WMFInterestArticleCardViewModel.identifier(title: result.title, project: resultProject)
                    let alreadySelected = self.gridViewModels.contains { $0.id == resultID && $0.isSelected }
                    let card = WMFInterestArticleCardViewModel(searchResult: result, project: resultProject, isSelected: alreadySelected)
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
        let pages = await interestsStore.loadPages()

        var cards: [WMFInterestArticleCardViewModel] = []
        var seenIDs = Set<String>()
        for page in pages {
            let card = WMFInterestArticleCardViewModel(title: page.title, project: page.project ?? project, isSelected: true)
            guard seenIDs.insert(card.id).inserted else { continue }
            cards.append(card)
        }

        gridViewModels = cards
        recountSelectedArticles()
    }

    /// Articles for the last selected topic, or the default grid when no topic is selected.
    private func reloadGrid() {
        if let topic = selectedTopics.last {
            fetchArticles(for: topic)
        } else {
            fetchSuggestedArticles()
        }
    }

    /// Rebuilds gridViewModels: currently selected VMs at top, then new random/topic articles, capped at maxGridArticles.
    /// Only called when the article list reloads — not on individual card selection.
    func buildGrid(from articles: [WMFRandomArticle]) {
        gridViewModels = gridViewModels.filter { $0.isSelected }
        appendToGrid(articles)
    }

    /// Adds articles the grid does not show yet, up to maxGridArticles.
    private func appendToGrid(_ articles: [WMFRandomArticle]) {
        var shownIDs = Set(gridViewModels.map { $0.id })
        for article in articles where gridViewModels.count < Self.maxGridArticles {
            let card = WMFInterestArticleCardViewModel(article: article, project: project)
            guard shownIDs.insert(card.id).inserted else { continue }
            gridViewModels.append(card)
        }
    }

    func fetchRandomArticles() {
        fetchTask?.cancel()
        isFetchingArticles = true
        fetchTask = Task { [weak self] in
            guard let self else { return }
            await loadRandomArticles()
            self.isFetchingArticles = false
        }
    }

    private func loadRandomArticles() async {
        do {
            let articles = try await dataController.fetchRandomArticles(project: project)
            guard !Task.isCancelled else { return }
            buildGrid(from: articles)
        } catch {
            // TODO: Error state
        }
    }

    /// No topic selected: the selected articles, then the store's suggestions. Random articles
    /// fill the grid when fewer than `minimumSuggestedCards` are shown, so a new reader still has
    /// something to pick. A store without suggestions gets random articles only.
    func fetchSuggestedArticles() {
        fetchTask?.cancel()
        isFetchingArticles = true
        fetchTask = Task { [weak self] in
            guard let self else { return }
            let suggestions = await interestsStore.suggestedPages()
            guard !Task.isCancelled else { return }
            guard let suggestions else {
                await loadRandomArticles()
                self.isFetchingArticles = false
                return
            }

            gridViewModels = gridViewModels.filter { $0.isSelected }
            var shownIDs = Set(gridViewModels.map { $0.id })
            for suggestion in suggestions where gridViewModels.count < Self.maxGridArticles {
                let card = WMFInterestArticleCardViewModel(title: suggestion.title, project: suggestion.project ?? project, isSelected: false)
                guard shownIDs.insert(card.id).inserted else { continue }
                gridViewModels.append(card)
            }

            if gridViewModels.count < Self.minimumSuggestedCards {
                let articles = (try? await dataController.fetchRandomArticles(project: project)) ?? []
                guard !Task.isCancelled else { return }
                appendToGrid(articles)
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

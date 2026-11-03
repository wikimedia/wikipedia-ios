import Foundation
import Combine
import WMFData

public protocol WMFSavedAllArticlesLoggingDelegate: AnyObject {
    @MainActor func savedAllArticlesDidTapArticle(_ article: WMFSavedArticle, fromLongPress: Bool)
    @MainActor func savedAllArticlesDidTapOpenInNewTab()
    @MainActor func savedAllArticlesDidTapShare(fromLongPress: Bool)
}

@MainActor
public final class WMFSavedAllArticlesViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public enum State {
        case loading
        case empty
        case data
        case undefined
    }
    
    // MARK: - Published Properties
    
    @Published public var articles: [WMFSavedArticle] = []
    @Published public var filteredArticles: [WMFSavedArticle] = []
    @Published public var state: State = .undefined
    @Published public var isEditing: Bool = false
    @Published public var hasSelection = false
    @Published public var searchText: String = ""
    @Published public private(set) var sortOrder: WMFReadingListSortOrder = .byRecentlyAdded
    /// Mirrors the shared Discover card so the list re-renders when the card is answered.
    @Published public private(set) var isAnnouncementVisible = false
    
    // MARK: - Properties
    
    private let dataController: WMFLegacyReadingListsDataController
    /// The Discover onboarding card shown above the list. Shared with the Reading lists segment.
    public var announcementViewModel: WMFDiscoverAnnouncementViewModel? {
        didSet { bindAnnouncement() }
    }
    private var announcementCancellable: AnyCancellable?
    public weak var loggingDelegate: WMFSavedAllArticlesLoggingDelegate?
    
    private var rowViewModelCache: [String: WMFPageRowSavedViewModel] = [:]
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Closures
    
    public typealias FromLongPress = Bool
    public var didTapArticle: ((WMFSavedArticle, FromLongPress) -> Void)?
    public var didTapShare: ((WMFSavedArticle, CGRect, FromLongPress) -> Void)?
    public var didTapAddToList: (([WMFSavedArticle]) -> Void)?
    public var didPullToRefresh: (() async -> Void)?
    public var didTapOpenInNewTab: ((WMFSavedArticle) -> Void)?
    public var didTapOpenInBackgroundTab: ((WMFSavedArticle) -> Void)?
    public var didUpdateEditingMode: ((Bool) -> Void)?
    public var didTapArticleAlert: ((WMFSavedArticle) -> Void)?
    public var didTapReadingListTag: ((WMFSavedArticle, String?) -> Void)?
    
    // MARK: - Initialization
    
    public init(dataController: WMFLegacyReadingListsDataController) {
        self.dataController = dataController
        setupSearchBinding()
    }

    deinit {
        loadTask?.cancel()
    }
    
    private func bindAnnouncement() {
        announcementCancellable = announcementViewModel?.$isVisible
            .sink { [weak self] isVisible in
                self?.isAnnouncementVisible = isVisible
            }
        if announcementViewModel == nil {
            isAnnouncementVisible = false
        }
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.filterArticles(with: text)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    public func loadArticles() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let fetchedArticles = (try? await dataController.fetchSavedArticles()) ?? []
            let sortOrder = (try? await dataController.savedArticlesSortOrder()) ?? .byRecentlyAdded
            let isSyncPending = fetchedArticles.isEmpty ? await dataController.isInitialSyncPending() : false
            guard !Task.isCancelled else { return }

            self.sortOrder = sortOrder
            self.articles = fetchedArticles
            self.filterArticles(with: self.searchText)
            self.state = fetchedArticles.isEmpty ? (isSyncPending ? .loading : .empty) : .data
        }
    }
    
    public func setSortOrder(_ sortOrder: WMFReadingListSortOrder) {
        self.sortOrder = sortOrder
        Task {
            try? await dataController.setSavedArticlesSortOrder(sortOrder)
            loadArticles()
        }
    }

    public func toggleEditing() {
        isEditing.toggle()
        rowViewModelCache.values.forEach {
            $0.isEditing = isEditing
            if !isEditing {
                $0.isSelected = false
            }
        }
        updateHasSelection()
        didUpdateEditingMode?(isEditing)
    }
    
    public func toggleSelection(for article: WMFSavedArticle) {
        guard let rowViewModel = rowViewModelCache[article.id] else { return }
            rowViewModel.isSelected.toggle()
        updateHasSelection()
    }
    
    private func updateHasSelection() {
        hasSelection = rowViewModelCache.values.contains { $0.isSelected }
    }
    
    public var selectedArticles: [WMFSavedArticle] {
        articles.filter { rowViewModelCache[$0.id]?.isSelected == true }
    }
    
    public func updateAlertType(id: String, alertType: WMFSavedArticleAlertType) {
        if let index = articles.firstIndex(where: { $0.id == id }) {
            articles[index].alertType = alertType
        }
        
        if let index = filteredArticles.firstIndex(where: { $0.id == id }) {
            filteredArticles[index].alertType = alertType
        }
        
        rowViewModelCache[id]?.alertType = alertType
    }
    
    public func deleteArticles(_ deletedArticles: [WMFSavedArticle], fromLongPress: Bool) {
        let deletedIDs = deletedArticles.map { $0.id }
        dataController.deleteSavedArticles(articles: deletedArticles, fromLongPress: fromLongPress, completion: { [weak self] confirmed in
            guard let self else { return }
            if confirmed {
                articles.removeAll(where: { deletedIDs.contains($0.id) })
                filteredArticles.removeAll(where: { deletedIDs.contains($0.id) })
                state = articles.isEmpty ? .empty : .data
            }
        })
    }
    
    public func deleteSelectedArticles() {
        deleteArticles(selectedArticles, fromLongPress: false)
        toggleEditing()
    }
    
    public func addSelectedToList() {
        didTapAddToList?(selectedArticles)
    }

    // MARK: - Taps

    public func tapArticle(_ article: WMFSavedArticle, fromLongPress: Bool) {
        loggingDelegate?.savedAllArticlesDidTapArticle(article, fromLongPress: fromLongPress)
        didTapArticle?(article, fromLongPress)
    }

    public func tapOpenInNewTab(_ article: WMFSavedArticle) {
        loggingDelegate?.savedAllArticlesDidTapOpenInNewTab()
        didTapOpenInNewTab?(article)
    }

    public func tapShare(_ article: WMFSavedArticle, cgRect: CGRect, fromLongPress: Bool) {
        loggingDelegate?.savedAllArticlesDidTapShare(fromLongPress: fromLongPress)
        didTapShare?(article, cgRect, fromLongPress)
    }
    
    func rowViewModel(for article: WMFSavedArticle) -> WMFPageRowSavedViewModel {
        if let cached = rowViewModelCache[article.id] {
            // reading list names may have changed
            // Defer the update to avoid publishing during view evaluation
            if cached.readingListNames != article.readingListNames {
                Task { @MainActor in
                    cached.readingListNames = article.readingListNames
                }
            }
            return cached
        }
        
        let vm = WMFPageRowSavedViewModel(
            id: article.id,
            title: article.displayTitle,
            project: article.project,
            description: article.description,
            snippet: article.snippet,
            thumbnailURL: article.thumbnailURL,
            readingListNames: article.readingListNames,
            alertType: article.alertType
        )
        
        vm.didTapAlert = { [weak self] in
            guard let self else { return }
            didTapArticleAlert?(currentArticle(id: article.id) ?? article)
        }
        
        vm.didTapReadingListTag = { [weak self] readingListName in
            guard let self else { return }
            didTapReadingListTag?(currentArticle(id: article.id) ?? article, readingListName)
        }
        
        rowViewModelCache[article.id] = vm
        return vm
    }
    
    // MARK: - Private Methods

    /// The row keeps its view model across reloads, so a tap must read the article as it is now,
    /// not as it was when the row was first built.
    private func currentArticle(id: String) -> WMFSavedArticle? {
        articles.first { $0.id == id }
    }
    
    private func filterArticles(with searchText: String) {
        filteredArticles = articles.filter { article in
            WMFLegacyReadingListsDataController.matches(article.displayTitle, searchText: searchText)
        }
    }
}

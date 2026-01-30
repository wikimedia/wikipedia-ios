import Foundation
import Combine
import WMFData

@MainActor
public final class WMFAllArticlesViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public struct LocalizedStrings {
        
        // empty state
        let emptyStateTitle: String
        let emptyStateMessage: String
        
        // bottom toolbar in editing mode
        let addToList: String
        let unsave: String
        
        // contextual menu
        let open: String
        let openInNewTab: String
        let openInBackgroundTab: String
        let removeFromSaved: String
        let share: String
        
        // alert error messages
        let listLimitExceeded: String
        let entryLimitExceeded: String
        let notSynced: String
        let articleQueuedToBeDownloaded: String
        
        public init(emptyStateTitle: String, emptyStateMessage: String, addToList: String, unsave: String, open: String, openInNewTab: String, openInBackgroundTab: String, removeFromSaved: String, share: String, listLimitExceeded: String, entryLimitExceeded: String, notSynced: String, articleQueuedToBeDownloaded: String) {
            self.emptyStateTitle = emptyStateTitle
            self.emptyStateMessage = emptyStateMessage
            self.addToList = addToList
            self.unsave = unsave
            self.open = open
            self.openInNewTab = openInNewTab
            self.openInBackgroundTab = openInBackgroundTab
            self.removeFromSaved = removeFromSaved
            self.share = share
            self.listLimitExceeded = listLimitExceeded
            self.entryLimitExceeded = entryLimitExceeded
            self.notSynced = notSynced
            self.articleQueuedToBeDownloaded = articleQueuedToBeDownloaded
        }
    }
    
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
    
    // MARK: - Properties
    
    public let localizedStrings: LocalizedStrings
    private let dataController: WMFLegacySavedArticlesDataController
    
    private var rowViewModelCache: [String: WMFAsyncPageRowSavedViewModel] = [:]
    
    // MARK: - Closures
    
    public var didTapArticle: ((WMFSavedArticle) -> Void)?
    public var didTapShare: ((WMFSavedArticle, CGRect) -> Void)?
    public var didTapAddToList: (([WMFSavedArticle]) -> Void)?
    public var didPullToRefresh: (() async -> Void)?
    public var didTapOpenInNewTab: ((WMFSavedArticle) -> Void)?
    public var didTapOpenInBackgroundTab: ((WMFSavedArticle) -> Void)?
    public var didUpdateEditingMode: ((Bool) -> Void)?
    public var didTapArticleAlert: ((WMFSavedArticle) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        dataController: WMFLegacySavedArticlesDataController,
        localizedStrings: LocalizedStrings
    ) {
        self.dataController = dataController
        self.localizedStrings = localizedStrings
        setupSearchBinding()
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
        
        // prevent duplicate loading
        guard state != .loading else {
            return
        }
        
        state = .loading
        articles = dataController.fetchAllSavedArticles()
        filteredArticles = articles
        state = articles.isEmpty ? .empty : .data
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
        
        let loopArticles = articles
        for (index, article) in loopArticles.enumerated() {
            var mutArticle = article
            if article.id == id {
                mutArticle.alertType = alertType
            }
            articles[index] = mutArticle
        }
        
        let loopFilteredArticles = filteredArticles
        for (index, article) in loopFilteredArticles.enumerated() {
            var mutArticle = article
            if article.id == id {
                mutArticle.alertType = alertType
            }
            filteredArticles[index] = mutArticle
        }
        
        let rowViewModel = rowViewModelCache[id]
        rowViewModel?.alertType = alertType
    }
    
    public func deleteArticle(_ article: WMFSavedArticle) {
        dataController.deleteSavedArticle(withProject: article.project, title: article.title)
        
        articles.removeAll { $0.id == article.id }
        filteredArticles.removeAll { $0.id == article.id }
        state = articles.isEmpty ? .empty : .data
    }
    
    public func deleteSelectedArticles() {
        for article in selectedArticles {
            deleteArticle(article)
        }
        toggleEditing()
    }
    
    public func addSelectedToList() {
        didTapAddToList?(selectedArticles)
    }
    
    func rowViewModel(for article: WMFSavedArticle) -> WMFAsyncPageRowSavedViewModel {
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
        
        let localizedStrings = WMFAsyncPageRowSavedViewModel.LocalizedStrings(
            open: localizedStrings.open,
            openInNewTab: localizedStrings.openInNewTab,
            openInBackgroundTab: localizedStrings.openInBackgroundTab,
            removeFromSaved: localizedStrings.removeFromSaved,
            share: localizedStrings.share,
            listLimitExceeded: localizedStrings.listLimitExceeded,
            entryLimitExceeded: localizedStrings.entryLimitExceeded,
            notSynced: localizedStrings.notSynced,
            articleQueuedToBeDownloaded: localizedStrings.articleQueuedToBeDownloaded)
        
        let vm = WMFAsyncPageRowSavedViewModel(id: article.id, title: article.title, project: article.project, readingListNames: article.readingListNames, alertType: article.alertType, localizedStrings: localizedStrings)
        
        vm.didTapAlert = { [weak self] in
            self?.didTapArticleAlert?(article)
        }
        
        rowViewModelCache[article.id] = vm
        return vm
    }
    
    // MARK: - Private Methods
    
    private func filterArticles(with searchText: String) {
        if searchText.isEmpty {
            filteredArticles = articles
        } else {
            filteredArticles = articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

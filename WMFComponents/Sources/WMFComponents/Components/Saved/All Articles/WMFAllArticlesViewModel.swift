import Foundation
import Combine
import WMFData

@MainActor
public final class WMFAllArticlesViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public struct LocalizedStrings {
        let title: String
        let emptyStateTitle: String
        let emptyStateMessage: String
        let cancel: String
        let addToList: String
        let unsave: String
        let share: String
        let delete: String
        
        public init(
            title: String,
            emptyStateTitle: String,
            emptyStateMessage: String,
            cancel: String,
            addToList: String,
            unsave: String,
            share: String,
            delete: String
        ) {
            self.title = title
            self.emptyStateTitle = emptyStateTitle
            self.emptyStateMessage = emptyStateMessage
            self.cancel = cancel
            self.addToList = addToList
            self.unsave = unsave
            self.share = share
            self.delete = delete
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
    @Published public var selectedArticleIDs: Set<String> = []
    @Published public var searchText: String = ""
    
    // MARK: - Properties
    
    public let localizedStrings: LocalizedStrings
    private let dataController: WMFLegacySavedArticlesDataController
    
    private var rowViewModelCache: [String: WMFAsyncPageRowSavedViewModel] = [:]
    
    // MARK: - Closures
    
    public var didTapArticle: ((WMFSavedArticle) -> Void)?
    public var didTapShare: ((WMFSavedArticle) -> Void)?
    public var didTapAddToList: (([WMFSavedArticle]) -> Void)?
    public var loggingDelegate: WMFAllArticlesLoggingDelegate?
    public var didPullToRefresh: (() async -> Void)?
    
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
        if !isEditing {
            selectedArticleIDs.removeAll()
        }
    }
    
    public func toggleSelection(for article: WMFSavedArticle) {
        if selectedArticleIDs.contains(article.id) {
            selectedArticleIDs.remove(article.id)
        } else {
            selectedArticleIDs.insert(article.id)
        }
    }
    
    public func isSelected(_ article: WMFSavedArticle) -> Bool {
        selectedArticleIDs.contains(article.id)
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
        let selectedArticles = articles.filter { selectedArticleIDs.contains($0.id) }
        for article in selectedArticles {
            deleteArticle(article)
        }
        selectedArticleIDs.removeAll()
        isEditing = false
    }
    
    public func shareSelectedArticles() {
        guard let selected = articles.filter({ selectedArticleIDs.contains($0.id) }).first else {
            return
        }
        didTapShare?(selected)
    }
    
    public func addSelectedToList() {
        let selected = articles.filter { selectedArticleIDs.contains($0.id) }
        didTapAddToList?(selected)
    }
    
    public var hasSelection: Bool {
        !selectedArticleIDs.isEmpty
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
        let vm = WMFAsyncPageRowSavedViewModel(id: article.id, title: article.title, project: article.project, readingListNames: article.readingListNames, alertType: article.alertType)
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

// MARK: - Logging Delegate

public protocol WMFAllArticlesLoggingDelegate: AnyObject {
    func logArticleTapped(_ article: WMFSavedArticle)
    func logArticleDeleted(_ article: WMFSavedArticle)
}

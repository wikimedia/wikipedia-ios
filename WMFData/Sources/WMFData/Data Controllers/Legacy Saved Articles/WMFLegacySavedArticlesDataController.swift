import Foundation

// WMFData/Sources/WMFData/Models/Saved Articles/WMFSavedArticle.swift

public struct WMFSavedArticle: Identifiable, Equatable {
    public let id: String // objectID URI string
    public let title: String
    public let project: WMFProject
    public let savedDate: Date?
    public let readingListNames: [String]

    public init(id: String, title: String, project: WMFProject, savedDate: Date?, readingListNames: [String]) {
        self.id = id
        self.title = title
        self.project = project
        self.savedDate = savedDate
        self.readingListNames = readingListNames
    }
}

public protocol WMFLegacySavedArticlesDataControllerDelegate: AnyObject {
    func fetchAllSavedArticles() -> [WMFSavedArticle]
    func deleteSavedArticle(with id: String) async throws
    func addArticleToReadingList(articleID: String, listName: String) async throws
}

public final class WMFLegacySavedArticlesDataController {
    
    public weak var delegate: WMFLegacySavedArticlesDataControllerDelegate?
    
    public init(delegate: WMFLegacySavedArticlesDataControllerDelegate? = nil) {
        self.delegate = delegate
    }
    
    public func fetchAllSavedArticles() -> [WMFSavedArticle] {
        return delegate?.fetchAllSavedArticles() ?? []
    }
    
    public func deleteSavedArticle(with id: String) async throws {
        try await delegate?.deleteSavedArticle(with: id)
    }
    
    public func addArticleToReadingList(articleID: String, listName: String) async throws {
        try await delegate?.addArticleToReadingList(articleID: articleID, listName: listName)
    }
}

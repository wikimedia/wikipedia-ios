import Foundation

public enum WMFSavedArticleAlertType: Equatable {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case genericNotSynced
    case downloading
    case articleError(String)
    case none
}

public struct WMFSavedArticle: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let project: WMFProject
    public let savedDate: Date?
    public var readingListNames: [String]
    public var alertType: WMFSavedArticleAlertType

    public init(id: String, title: String, project: WMFProject, savedDate: Date?, readingListNames: [String], alertType: WMFSavedArticleAlertType = .none) {
        self.id = id
        self.title = title
        self.project = project
        self.savedDate = savedDate
        self.readingListNames = readingListNames
        self.alertType = alertType
    }
}

public protocol WMFLegacySavedArticlesDataControllerDelegate: AnyObject {
    func fetchAllSavedArticles() async throws -> [WMFSavedArticle]
    func deleteSavedArticles(articles: [WMFSavedArticle], completion: @escaping (Bool) -> Void)
}

public final class WMFLegacySavedArticlesDataController {
    
    public weak var delegate: WMFLegacySavedArticlesDataControllerDelegate?
    
    public init(delegate: WMFLegacySavedArticlesDataControllerDelegate? = nil) {
        self.delegate = delegate
    }
    
    public func fetchAllSavedArticles() async -> [WMFSavedArticle] {
        return (try? await delegate?.fetchAllSavedArticles() ?? []) ?? []
    }
    
    public func deleteSavedArticles(articles: [WMFSavedArticle], completion: @escaping (Bool) -> Void) {
        delegate?.deleteSavedArticles(articles: articles, completion: completion)
    }
}

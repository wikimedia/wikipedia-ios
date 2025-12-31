import Foundation

public actor WMFArticleDataController {
    
    private let mediaWikiService: WMFService?
    
    public init(mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.mediaWikiService = mediaWikiService
    }
    
    public struct ArticleInfoRequest: Sendable {
        let needsWatchedStatus: Bool
        let needsRollbackRights: Bool
        let needsCategories: Bool
        
        public init(needsWatchedStatus: Bool, needsRollbackRights: Bool, needsCategories: Bool) throws {
            self.needsWatchedStatus = needsWatchedStatus
            self.needsRollbackRights = needsRollbackRights
            self.needsCategories = needsCategories
            
            guard needsWatchedStatus == true ||
                    needsRollbackRights == true ||
                    needsCategories == true else {
                throw WMFServiceError.invalidRequest
            }
        }
    }
    
    struct ArticleInfoResponse: Codable, Sendable {

        struct Query: Codable, Sendable {

            struct Page: Codable, Sendable {
                
                struct Category: Codable, Sendable {
                    let ns: Int
                    let title: String
                }
                
                let title: String
                let watched: Bool?
                let watchlistexpiry: String?
                let categories: [Category]?
            }

            struct UserInfo: Codable, Sendable {
                let name: String
                let rights: [String]
            }

            let pages: [Page]
            let userinfo: UserInfo?
        }

        let query: Query
    }
    
    public struct WMFArticleInfoResponse: Sendable {
        public let watched: Bool
        public let watchlistExpiry: Date?
        public let userHasRollbackRights: Bool?
        public let categories: [String]
    }

    
    /// Fetches possible info needed from MediaWiki for a particular article. Watch status, user rollback rights, categories. The idea here is to fetch all we need for article display in a single call so the app only needs to make an API call to MediaWiki once upon article view.
    /// - Parameters:
    ///   - title: Title of the article
    ///   - project: Project the article belongs to (EN Wiki, etc)
    ///   - request: Request struct to fetch certain pieces of data. So far can support watchlist status and user rollback rights.
    public func fetchArticleInfo(title: String, project: WMFProject, request: ArticleInfoRequest) async throws -> WMFArticleInfoResponse {
         
        guard let mediaWikiService else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        var parameters = [
            "action": "query",
            "titles": title,
            "errorsuselocal": "1",
            "errorformat": "html",
            "format": "json",
            "formatversion": "2"
        ]
        
        if request.needsWatchedStatus {
            parameters["prop"] = "info"
            parameters["inprop"] = "watched"
        }
        
        if request.needsCategories {
            if request.needsWatchedStatus {
                parameters["prop"] = "info|categories"
            } else {
                parameters["prop"] = "categories"
            }
            
            parameters["clshow"] = "!hidden"
            parameters["cllimit"] = "500"
        }

        if request.needsRollbackRights {
            parameters["meta"] = "userinfo"
            parameters["uiprop"] = "rights"
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let serviceRequest = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        let response: ArticleInfoResponse = try await withCheckedThrowingContinuation { continuation in
            mediaWikiService.performDecodableGET(request: serviceRequest) { (result: Result<ArticleInfoResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        guard let firstPage = response.query.pages.first else {
            throw WMFDataControllerError.unexpectedResponse
        }

        let watched = firstPage.watched ?? false
        let userHasRollbackRights = response.query.userinfo?.rights.contains("rollback")
         
        var watchlistExpiry: Date? = nil
        if let watchlistExpiryString = firstPage.watchlistexpiry {
            watchlistExpiry = DateFormatter.mediaWikiAPIDateFormatter.date(from: watchlistExpiryString)
        }
         
        var categoryTitles: [String] = []
        if let responseCategories = firstPage.categories {
            for category in responseCategories {
                categoryTitles.append(category.title)
            }
        }

        return WMFArticleInfoResponse(watched: watched, watchlistExpiry: watchlistExpiry, userHasRollbackRights: userHasRollbackRights, categories: categoryTitles)
    }
}

// MARK: - Sync Bridge Extension

extension WMFArticleDataController {
    
    nonisolated public func fetchArticleInfoSyncBridge(title: String, project: WMFProject, request: ArticleInfoRequest, completion: @escaping @Sendable (Result<WMFArticleInfoResponse, Error>) -> Void) {
        Task {
            do {
                let response = try await self.fetchArticleInfo(title: title, project: project, request: request)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

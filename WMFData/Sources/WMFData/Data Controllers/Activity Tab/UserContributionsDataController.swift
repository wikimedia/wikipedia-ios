import Foundation

public final class UserContributionsDataController {
    
    public static let shared = UserContributionsDataController()
    
    private init() {}
    
    public func fetchEditCount(
        globalUserID: Int,
        startDate: Date? = nil,
        endDate: Date? = nil,
        maxLimit: Int = 500
    ) async throws -> Int {
        
        let dataController = WMFGlobalEditCountDataController(globalUserID: globalUserID)
        
        if let startDate, let endDate {
            return try await dataController.fetchEditCount(
                startDate: startDate,
                endDate: endDate
            )
        } else {
            return try await dataController.fetchEditCount()
        }
    }
    
    public func fetchRecentArticleEdits(username: String) async throws -> [TimelineItem] {
        
        let service = WMFDataEnvironment.current.mediaWikiService
        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let project = WMFProject.wikipedia(primaryAppLanguage)
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "list": "usercontribs",
            "ucuser": username,
            "uclimit": "500",
            "ucnamespace": "0",
            "ucprop": "ids|title|timestamp"
        ]
        
        let request = WMFMediaWikiServiceRequest(
            url: url,
            method: .GET,
            backend: .mediaWiki,
            parameters: parameters
        )
        
        let response: UserContributionsAPIResponse =
        try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<UserContributionsAPIResponse, Error>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        guard let contribs = response.query?.usercontribs else {
            return []
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        return contribs.compactMap { contrib in
            guard let timestamp = isoFormatter.date(from: contrib.timestamp) else { return nil }
            let articleURL = project.siteURL?.wmfURL(withTitle: contrib.title)
            
            return TimelineItem(
                id: "\(contrib.pageid)-\(contrib.revid)",
                date: timestamp,
                titleHtml: contrib.title,
                projectID: project.id,
                pageTitle: contrib.title,
                url: articleURL,
                namespaceID: 0,
                revisionID: contrib.revid,
                parentRevisionID: contrib.parentid,
                itemType: .edit
            )
        }
    }
}

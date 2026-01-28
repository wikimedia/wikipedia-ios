import Foundation

public final class UserContributionsDataController {
    
    public static let shared = UserContributionsDataController()
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    private init() {}
    
    public func fetchRecentEdits(username: String) async throws -> [ArticleEdit] {
        
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
            
            return ArticleEdit(
                pageID: contrib.pageid,
                revisionID: contrib.revid,
                parentRevisionID: contrib.parentid,
                title: contrib.title,
                date: timestamp,
                projectID: project.id,
                url: articleURL
            )
        }
    }
    
    public func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String, completion: @escaping (Result<(Int, Bool), Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        guard let project = project else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        // We have to switch the dates here before sending into the API.
        // It is expected that this method's startDate parameter is chronologically earlier than endDate. This is how the remote feature config is set up.
        // The User Contributions API expects ucend to be chronologically earlier than ucstart, because it pages backwards so that the most recent edits appear on the first page.
        let ucStartDate = endDate
        let ucEndDate = startDate

        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "list": "usercontribs",
            "formatversion": "2",
            "uclimit": "500",
            "ucstart": ucStartDate,
            "ucend": ucEndDate,
            "ucuser": username,
            "ucprop": "ids|title|timestamp|tags|flags"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        service.performDecodableGET(request: request) { (result: Result<UserContributionsAPIResponse, Error>) in
            switch result {
            case .success(let response):
                guard let query = response.query else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }

                let editCount = query.usercontribs.count

                let hasMoreEdits = response.continue?.uccontinue != nil

                completion(.success((editCount, hasMoreEdits)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

public struct ArticleEdit: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let projectID: String
    public let date: Date
    public let pageID: Int
    public let revisionID: Int
    public let parentRevisionID: Int?
    public let url: URL?
    
    public init(pageID: Int, revisionID: Int, parentRevisionID: Int?, title: String, date: Date, projectID: String, url: URL? ) {
        self.id = "\(pageID)-\(revisionID)"
        self.pageID = pageID
        self.revisionID = revisionID
        self.parentRevisionID = parentRevisionID
        self.title = title
        self.date = date
        self.projectID = projectID
        self.url = url
    }
}

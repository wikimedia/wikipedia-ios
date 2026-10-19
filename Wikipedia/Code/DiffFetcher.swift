import Foundation
import WMFData

enum DiffFetcherError: Error {
    case failureParsingRevisions
    case failureParsingWikitext
    case failureParsingTitle
}

class DiffFetcher: Fetcher {
    
    enum FetchRevisionModelRequestDirection: String {
        case older
        case newer
    }
    
    func fetchDiff(fromRevisionId: Int, toRevisionId: Int, siteURL: URL, completion: @escaping ((Result<DiffResponse, Error>) -> Void)) {
        
        guard let url = compareURL(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, siteURL: siteURL) else {
            completion(.failure(DiffError.generateUrlFailure))
            return
        }
        
        session.jsonDecodableTask(with: url) { (result: DiffResponse?, urlResponse: URLResponse?, error: Error?) in
            
            guard let result = result else {
                completion(.failure(DiffError.missingDiffResponseFailure))
                return
            }
            
            guard urlResponse != nil else {
                completion(.failure(DiffError.missingUrlResponseFailure))
                return
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(result))
        }
    }
    
    func fetchWikitext(siteURL: URL, revisionId: Int, completion: @escaping (Result<String, Error>) -> Void) {
        
        let params: [String: Any] = [
            "action": "query",
            "prop": "revisions",
            "revids": "\(revisionId)",
            "rvprop": "content",
            "format": "json"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { (result, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let query = result?["query"] as? [String: AnyObject],
                let pages = query["pages"] as? [String: AnyObject] else {
                completion(.failure(DiffFetcherError.failureParsingWikitext))
                return
            }
            
            var maybeResult: String?
            for (_, value) in pages {
                guard let valueDict = value as? [String: AnyObject] else {
                    continue
                }
                
                if let revisionsArray = valueDict["revisions"] as? [[String: AnyObject]],
                    revisionsArray.count > 0 {
                    
                    for revision in revisionsArray {
                        
                        if let text = revision["*"] as? String {
                            maybeResult = text
                            break
                        }
                            
                    }
                }
            }
            
            guard let result = maybeResult else {
                completion(.failure(DiffFetcherError.failureParsingWikitext))
                return
            }
            
            completion(.success(result))
        }
    }
    
    private func compareURL(fromRevisionId: Int, toRevisionId: Int, siteURL: URL) -> URL? {
        
        guard siteURL.host != nil else {
            return nil
        }

        var pathComponents = ["v1", "revision"]
        pathComponents.append("\(fromRevisionId)")
        pathComponents.append("compare")
        pathComponents.append("\(toRevisionId)")
        return configuration.mediaWikiRestAPIURLForURL(siteURL, appending: pathComponents)
    }
    
    enum FetchRevisionModelRequest {
        case adjacent(sourceRevision: WMFPageRevision, direction: FetchRevisionModelRequestDirection)
        case populateModel(revisionID: Int)
    }

    /// Fetch one revision. The request selects the revision by ID, or the revision next to a source revision.
    func fetchRevisionModel(_ siteURL: URL, articleTitle: String, request: FetchRevisionModelRequest, completion: @escaping ((Result<WMFPageRevision, Error>) -> Void)) {
        guard let project = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            completion(.failure(DiffFetcherError.failureParsingRevisions))
            return
        }

        Task {
            do {
                let revision: WMFPageRevision
                switch request {
                case .populateModel(let revisionID):
                    revision = try await WMFPageHistoryDataController.shared.fetchRevision(project: project, title: articleTitle, revisionID: revisionID)
                case .adjacent(let sourceRevision, let direction):
                    let fetchDirection: WMFPageHistoryDataController.Direction = direction == .older ? .older : .newer
                    revision = try await WMFPageHistoryDataController.shared.fetchAdjacentRevision(project: project, title: articleTitle, revisionID: sourceRevision.revisionID, direction: fetchDirection)
                }
                completion(.success(revision))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Fetch the first revision of the article.
    public func fetchFirstRevisionModel(siteURL: URL, articleTitle: String, completion: @escaping (Result<WMFPageRevision, Error>) -> Void) {
        guard let project = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            completion(.failure(DiffFetcherError.failureParsingRevisions))
            return
        }

        Task {
            do {
                let revision = try await WMFPageHistoryDataController.shared.fetchFirstRevision(project: project, title: articleTitle)
                completion(.success(revision))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func fetchArticleTitle(siteURL: URL, revisionID: Int, completion: @escaping (Result<String, Error>) -> Void) {
        let parameters: [String: Any] = [
            "action": "query",
            "revids": revisionID,
            "format": "json"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: parameters, cancellationKey: nil) { (result, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let query = result?["query"] as? [String : Any],
                let pages = query["pages"] as? [String : Any] else {
                    completion(.failure(DiffFetcherError.failureParsingTitle))
                    return
            }
            
            for (_, value) in pages {
                
                guard let value = value as? [String: Any] else {
                    completion(.failure(DiffFetcherError.failureParsingTitle))
                    return
                }
                
                guard let title = value["title"] as? String else {
                    completion(.failure(DiffFetcherError.failureParsingTitle))
                    return
                }
                
                completion(.success(title))
                return
            }
            
            completion(.failure(DiffFetcherError.failureParsingTitle))
        }
    }
}

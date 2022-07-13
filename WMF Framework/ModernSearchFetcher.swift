import Foundation

@MainActor
public class ModernSearchFetcher: Fetcher {
    
    public struct SearchResult: Hashable {
        public let url: URL
        public let title: String
        let pageId: Int
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(pageId)
        }
    }
    
    public func fetchArticles(searchTerm: String, siteURL: URL, resultLimit: UInt) async throws -> [SearchResult] {
        try await withCheckedThrowingContinuation { continuation in
            fetchArticles(searchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, completion: { result in
                switch result {
                case .success(let searchResults):
                    continuation.resume(returning: searchResults)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    private func fetchArticles(searchTerm: String, siteURL: URL, resultLimit: UInt, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        let params: [String: Any] = [
            "action": "query",
            "prop": "description|pageprops|pageimages|revisions|coordinates",
            "coprop": "type|dim",
            "ppprop": "displaytitle",
            "generator": "search",
            "gsrsearch": searchTerm,
            "gsrnamespace": 0,
            "gsrwhat": "text",
            "gsrinfo": "",
            "gsrprop": "redirecttitle",
            "gsroffset": 0,
            "gsrlimit": resultLimit,
            "piprop": "thumbnail",
            "pithumbsize": UIScreen.main.wmf_listThumbnailWidthForScale() ?? 150,
            "pilimit": resultLimit,
            "rvprop": "ids",
            "continue": "",
            "format": "json",
            "redirects": 1
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { result, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let response = response,
               response.statusCode != 200 {
                completion(.failure(RequestError.http(response.statusCode)))
                return
            }
            
            if let queryObject = result?["query"] as? [String: Any],
               let pagesObject = queryObject["pages"] as? [String: Any] {
                
                var searchResults: [SearchResult] = []
                for (_, value) in pagesObject {
                    if let valueDictionary = value as? [String: Any],
                    let pageId = valueDictionary["pageid"] as? Int,
                    let title = valueDictionary["title"] as? String,
                       let url = URL.wmf_URL(withSiteURL: siteURL, title: title) {
                        let searchResult = SearchResult(url: url, title: title, pageId: pageId)
                        searchResults.append(searchResult)
                    }
                }
                
                completion(.success(searchResults))
            }
        }
    }
}

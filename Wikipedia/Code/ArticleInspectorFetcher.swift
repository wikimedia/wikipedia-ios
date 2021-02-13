
import Foundation

class ArticleInspectorFetcher: Fetcher {
    
    enum FetchError: Error {
        case articleTitleContainsSpaces
        case wikiWhoUrlInstantiationFailed
        case missingWikiWhoResponse
    }
    
    func fetchWikiWho(articleTitle: String, completion: @escaping (Result<WikiWhoResponse, Error>) -> Void) {
        
        do {
            let url = try wikiWhoURL(articleTitle: articleTitle)
            
            let _ = session.jsonDecodableTask(with: url) { (wikiWhoResponse: WikiWhoResponse?, httpResponse, error) in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode,
                    statusCode != 200 {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                
                guard let wikiWhoResponse = wikiWhoResponse else {
                    completion(.failure(FetchError.missingWikiWhoResponse))
                    return
                }
                
                completion(.success(wikiWhoResponse))
            }
            
        } catch (let error) {
            completion(.failure(error))
        }
    }
}

private extension ArticleInspectorFetcher {
    func wikiWhoURL(articleTitle: String) throws -> URL {
        
        guard !articleTitle.contains(" ") else {
            throw FetchError.articleTitleContainsSpaces
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wikiwho-ios-experiments.wmflabs.org"
        components.path = "/whocolor/\(articleTitle)/"
        
        guard let url = components.url else {
            throw FetchError.wikiWhoUrlInstantiationFailed
        }
        
        return url
    }
}

import Foundation

public class ModernRelatedSearchFetcher: Fetcher {
    private let relatedSearchFetcher = RelatedSearchFetcher()
    
    public func fetchRelatedArticles(articleTitle: String, siteURL: URL) async throws -> [ModernSearchFetcher.SearchResult] {
        
        guard let denormalizedTitle = articleTitle.denormalizedPageTitle else {
            throw RequestError.invalidParameters
        }
        
        let result: [ModernSearchFetcher.SearchResult] = try await withCheckedThrowingContinuation { continuation in
            
            relatedSearchFetcher.fetchRelatedArticles(articleTitle: denormalizedTitle, siteURL: siteURL) { error, dictionary in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let dictionary = dictionary {
                    
                    let summaries: [ArticleSummary] = Array(dictionary.values)
                    
                    let searchResults: [ModernSearchFetcher.SearchResult] = summaries.compactMap {
                        
                        guard let pageId = $0.id,
                              let title = $0.title,
                              let url = URL.wmf_URL(withSiteURL: siteURL, title: title) else {
                            return nil
                        }
                        
                        return ModernSearchFetcher.SearchResult(url: url, title: title, pageId: Int(pageId))
                    }
                    
                    continuation.resume(returning: searchResults)
                    return
                }
                
                continuation.resume(throwing: RequestError.unexpectedResponse)
            }
        }
        
        return result
    }
}

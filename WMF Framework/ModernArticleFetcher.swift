import Foundation

class ModernArticleFetcher: Fetcher {
    
    private let articleFetcher = ArticleFetcher()
    
   public func fetchArticleSummaryResponsesForArticles(withKeys articleKeys: [WMFInMemoryURLKey]) async throws -> [WMFInMemoryURLKey: ArticleSummary] {
       
       return try await withThrowingTaskGroup(of: [WMFInMemoryURLKey: ArticleSummary].self) { group -> [WMFInMemoryURLKey: ArticleSummary] in
           for articleKey in articleKeys {
               group.addTask {
                   let articleSummary = try await self.fetchSummaryForArticle(with: articleKey)
                   return [articleKey: articleSummary]
               }
           }
           
           var finalResults: [WMFInMemoryURLKey: ArticleSummary] = [:]
           for try await singleResult in group {
               for (key, value) in singleResult {
                   finalResults[key] = value
               }
           }
           
           return finalResults
       }
    }
    
    public func fetchSummaryForArticle(with articleKey: WMFInMemoryURLKey) async throws -> ArticleSummary {
        
        guard let articleURL = articleKey.url else {
            throw Fetcher.invalidParametersError
        }
        
        let summaryURL = try articleFetcher.summaryURL(articleURL: articleURL)
        let urlRequest =  URLRequest(url: summaryURL)
        
        let result: ArticleSummary = try await withCheckedThrowingContinuation { continuation in
        
            trackedJSONDecodableTask(with: urlRequest) { (result: Result<ArticleSummary, Error>, response) in
                switch result {
                case .success(let summary):
                    summary.languageVariantCode = articleKey.languageVariantCode
                    continuation.resume(returning: summary)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        return result
    }
}

import Intents
import WMF

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
                guard intent is GenerateReadingListIntent else {
                    fatalError("Unhandled Intent error : \(intent)")
                }
        return GenerateReadingListIntentHandler()
    }
    
}

class GenerateReadingListIntentHandler : NSObject, GenerateReadingListIntentHandling {
    
    enum HandlerError: Error {
        case missingSearchResults
        case unableToCreateWMFArticles
    }
    
    let siteURL = URL(string: "https://en.wikipedia.org")!

    func handle(intent: GenerateReadingListIntent) async -> GenerateReadingListIntentResponse {
        guard let sourceTexts = intent.sourceTexts,
              let readingListName = intent.readingListName else {
            return GenerateReadingListIntentResponse(code: .failure, userActivity: nil)
        }
        
        do {
            let searchResults = try await fetchArticles(searchTerms: sourceTexts)
            let articleTitles = searchResults.map { $0.title }
            let relatedResults = try await fetchRelatedArticles(articleTitles: articleTitles)
            let finalResults = searchResults + relatedResults
            try await createArticleSummaries(finalResults: finalResults)
            try await createReadingList(named: readingListName, results: finalResults.reversed()) // reversed so original search results show up first
            return GenerateReadingListIntentResponse.success(result: "Your \"\(readingListName)\" reading list was generated with \(finalResults.count) articles, sourced from \(sourceTexts.count) source texts.")
        } catch {
            return GenerateReadingListIntentResponse(code: .failure, userActivity: nil)
        }
    }
    
    @MainActor // ModernSearchFetcher init fails without this
    func fetchArticles(searchTerms: [String]) async throws -> [ModernSearchFetcher.SearchResult] {
        let modernFetcher = ModernSearchFetcher()
        
        return try await withThrowingTaskGroup(of: ModernSearchFetcher.SearchResult.self) { group -> [ModernSearchFetcher.SearchResult] in
            for searchTerm in searchTerms {
                group.addTask {
                    let searchResults = try await modernFetcher.fetchArticles(searchTerm: searchTerm, siteURL: self.siteURL, resultLimit: 1)
                    guard let searchResult = searchResults.first else {
                        throw HandlerError.missingSearchResults
                    }
                    
                    return searchResult
                }
            }
                    
            var searchResults = [ModernSearchFetcher.SearchResult]()
                    
            for try await searchResult in group {
                searchResults.append(searchResult)
            }
                    
            return searchResults
        }
    }
    
    @MainActor // RelatedSearchFetcher init probably fails without this
    func fetchRelatedArticles(articleTitles: [String]) async throws -> Set<ModernSearchFetcher.SearchResult> {
        let relatedFetcher = ModernRelatedSearchFetcher()
        
        let maxNumberOfRelated = 20 / articleTitles.count
        
        let dedupedRelatedSearchResults: Set<ModernSearchFetcher.SearchResult> = try await withThrowingTaskGroup(of: [ModernSearchFetcher.SearchResult].self) { group -> Set<ModernSearchFetcher.SearchResult> in
            for title in articleTitles {
                group.addTask {
                    return try await relatedFetcher.fetchRelatedArticles(articleTitle: title, siteURL: self.siteURL)
                }
            }
                    
            var finalResults = Set<ModernSearchFetcher.SearchResult>()
                    
            for try await searchResults in group {
                for searchResult in searchResults.prefix(maxNumberOfRelated) {
                    finalResults.insert(searchResult)
                }
            }
                    
            return finalResults
        }
        
        return dedupedRelatedSearchResults
    }
    
    @MainActor
    func createArticleSummaries(finalResults: [ModernSearchFetcher.SearchResult]) async throws {
        let dataStore = MWKDataStore.shared()
        let articleSummaryController = ModernArticleSummaryController(dataStore: dataStore)
        let keys = finalResults.compactMap { $0.url.wmf_inMemoryKey }
        _ = try await articleSummaryController.updateOrCreateArticleSummariesForArticles(withKeys: keys)
    }
    
    @MainActor
    func createReadingList(named name: String, results: [ModernSearchFetcher.SearchResult]) throws {
        let dataStore = MWKDataStore.shared()
        let articles = results.compactMap { dataStore.fetchOrCreateArticle(with: $0.url)}
        guard !articles.isEmpty else {
            throw HandlerError.unableToCreateWMFArticles
        }
        
        _ = try dataStore.readingListsController.createReadingList(named: name, description: "Generated from Siri Shortcuts", with: articles)
    }
    
    func resolveSourceTexts(for intent: GenerateReadingListIntent) async -> [INStringResolutionResult] {
        print("resolvingSourceTexts!")

        guard let sourceTexts = intent.sourceTexts else {
            // for some reason I can't seem to trigger MULTIPLE source text prompts. I'm not sure what I need to do.
            return [INStringResolutionResult.needsValue(), INStringResolutionResult.needsValue()]
        }

        return sourceTexts.map { INStringResolutionResult.success(with: $0) }
    }
    
    func resolveReadingListName(for intent: GenerateReadingListIntent) async -> INStringResolutionResult {
        print("Resolving reading list name!")
        
        guard let readingListName = intent.readingListName else {
            return INStringResolutionResult.needsValue()
        }
        
        return INStringResolutionResult.success(with: readingListName)
    }
    
    
}

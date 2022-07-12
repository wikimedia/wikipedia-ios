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
    var searchFetcher: ModernSearchFetcher?

    func handle(intent: GenerateReadingListIntent) async -> GenerateReadingListIntentResponse {
        guard let sourceTexts = intent.sourceTexts,
              let readingListName = intent.readingListName else {
            return GenerateReadingListIntentResponse(code: .failure, userActivity: nil)
        }
        
        do {
            let results = try await fetchArticles(searchTerms: sourceTexts)
            try await createReadingList(named: readingListName, searchResults: results)
            return GenerateReadingListIntentResponse.success(result: "Your \"\(readingListName)\" reading list was generated from \(sourceTexts.count) source texts.")
        } catch {
            return GenerateReadingListIntentResponse(code: .failure, userActivity: nil)
        }
    }
    
    @MainActor // ModernSearchFetcher init fails without this
    func fetchArticles(searchTerms: [String]) async throws -> [ModernSearchFetcher.SearchResult] {
        let modernFetcher = ModernSearchFetcher()
        self.searchFetcher = modernFetcher
        
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
    
    @MainActor
    func createReadingList(named name: String, searchResults: [ModernSearchFetcher.SearchResult]) throws {
        let dataStore = MWKDataStore.shared()
        let articles = searchResults.compactMap { dataStore.fetchOrCreateArticle(with: $0.url)}
        guard !articles.isEmpty else {
            throw HandlerError.unableToCreateWMFArticles
        }
        
        _ = try dataStore.readingListsController.createReadingList(named: name, description: "I hope this works!", with: articles)
    }
    
    func resolveSourceTexts(for intent: GenerateReadingListIntent) async -> [INStringResolutionResult] {
        print("resolvingSourceTexts!")

        guard let sourceTexts = intent.sourceTexts else {
            // for some reason I can't seem to trigger MULTIPLE source texxt prompts. I'm not sure what I need to do.
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

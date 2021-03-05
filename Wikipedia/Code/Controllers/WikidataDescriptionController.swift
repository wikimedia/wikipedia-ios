
import Foundation

class WikidataDescriptionController: ArticleDescriptionControlling {

    private let fetcher: WikidataFetcher
    private let wikidataDescription: String?
    private let wikiDataID: String
    let article: WMFArticle
    let articleLanguage: String
    let descriptionSource: ArticleDescriptionSource
    
    init?(article: WMFArticle, articleLanguage: String, descriptionSource: ArticleDescriptionSource, fetcher: WikidataFetcher = WikidataFetcher()) {
        self.fetcher = fetcher
        self.wikidataDescription = article.wikidataDescription
        self.article = article
        self.articleLanguage = articleLanguage
        self.descriptionSource = descriptionSource
        
        guard let wikiDataID = article.wikidataID else {
            return nil
        }
        
        self.wikiDataID = wikiDataID
    }
    
    func currentDescription(completion: @escaping (String?) -> Void) {
        completion(wikidataDescription)
    }
    
    func publishDescription(_ description: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        fetcher.publish(newWikidataDescription: description, from: descriptionSource, forWikidataID: wikiDataID, language: articleLanguage) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func errorTextFromError(_ error: Error) -> String {
        let apiErrorCode = (error as? WikidataAPIResult.APIError)?.code
        let errorText = apiErrorCode ?? "\((error as NSError).domain)-\((error as NSError).code)"
        return errorText
    }
    
    func learnMoreViewControllerWithTheme(_ theme: Theme) -> UIViewController? {
        return DescriptionHelpViewController.init(theme: theme)
    }
}


import Foundation

enum WikidataDescriptionControllerError: Error {
    case missingSelf
    case articleMissingWikidataID
}

class WikidataDescriptionController: ArticleDescriptionControlling {

    private let fetcher: WikidataFetcher
    var article: WMFArticle
    let articleLanguage: String
    let descriptionSource: ArticleDescriptionSource
    private var lastPublishedWikidataDescription: String?
    
    init?(article: WMFArticle, articleLanguage: String, descriptionSource: ArticleDescriptionSource, fetcher: WikidataFetcher = WikidataFetcher()) {
        self.fetcher = fetcher
        self.article = article
        self.articleLanguage = articleLanguage
        self.descriptionSource = descriptionSource
        
        guard article.wikidataID != nil else {
            return nil
        }
    }
    
    func currentDescription(completion: @escaping (String?) -> Void) {
        completion(lastPublishedWikidataDescription ?? article.wikidataDescription)
    }
    
    func publishDescription(_ description: String, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        guard let wikidataID = article.wikidataID else {
            completion(.failure(WikidataDescriptionControllerError.articleMissingWikidataID))
            return
        }
        
        fetcher.publish(newWikidataDescription: description, from: descriptionSource, forWikidataID: wikidataID, language: articleLanguage) { [weak self] (error) in
            
            guard let self = self else {
                completion(.failure(WikidataDescriptionControllerError.missingSelf))
                return
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.lastPublishedWikidataDescription = description
            completion(.success(ArticleDescriptionPublishResult(newRevisionID: nil, newDescription: description)))
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

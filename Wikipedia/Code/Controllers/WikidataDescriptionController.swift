import Foundation
import WMF

class WikidataDescriptionController: ArticleDescriptionControlling {

    private let fetcher: WikidataFetcher
    private let wikidataDescription: String?
    private let wikiDataID: String
    let article: WMFArticle
    let articleLanguageCode: String
    let descriptionSource: ArticleDescriptionSource
    
    init?(article: WMFArticle, articleLanguageCode: String, descriptionSource: ArticleDescriptionSource, fetcher: WikidataFetcher = WikidataFetcher()) {
        self.fetcher = fetcher
        self.wikidataDescription = article.wikidataDescription
        self.article = article
        self.articleLanguageCode = articleLanguageCode
        self.descriptionSource = descriptionSource
        
        guard let wikiDataID = article.wikidataID else {
            return nil
        }
        
        self.wikiDataID = wikiDataID
    }
    
    func currentDescription(completion: @escaping (String?, MediaWikiAPIDisplayError?) -> Void) {
        
        fetcher.wikidataBlockedInfo(forEntity: wikiDataID) { blockedError in
            DispatchQueue.main.async {
                completion(self.wikidataDescription, blockedError)
            }
        }
    }
    
    func publishDescription(_ description: String, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        fetcher.publish(newWikidataDescription: description, from: descriptionSource, forWikidataID: wikiDataID, languageCode: articleLanguageCode) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(ArticleDescriptionPublishResult(newRevisionID: nil, newDescription: description)))
        }
    }
    
    func errorCodeFromError(_ error: Error) -> String {
        var apiErrorCode: String?
        if let publishError = error as? WikidataFetcher.WikidataPublishingError {
            switch publishError {
            case .apiOther(let error):
                apiErrorCode = error.code
            case .apiBlocked(let blockedError):
                apiErrorCode = blockedError.code
            default:
                break
            }
        }
        let errorText = apiErrorCode ?? "\((error as NSError).domain)-\((error as NSError).code)"
        return errorText
    }
    
    func learnMoreViewControllerWithTheme(_ theme: Theme) -> UIViewController? {
        return DescriptionHelpViewController.init(theme: theme)
    }
    
    func warningTypesForDescription(_ description: String?) -> ArticleDescriptionWarningTypes {
        
        var warningTypes: ArticleDescriptionWarningTypes = []
        
        if descriptionIsTooLong(description) {
            warningTypes.insert(.length)
        }
        
        if descriptionIsUppercase(description) {
            warningTypes.insert(.casing)
        }
        
        return warningTypes
    }
}

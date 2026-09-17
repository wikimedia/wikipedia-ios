import Foundation
import WMF
import WMFData

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
    
    /// URL of the Wikidata entity page. Edit analytics use this URL because the edit creates its revision on wikidatawiki, not on the article's wiki.
    var loggingPageURL: URL? {
        return WMFProject.wikidata.siteURL?.wmf_URL(withTitle: wikiDataID)
    }

    func publishDescription(_ description: String, editType: ArticleDescriptionEditType, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        let editTag: WMFEditTag = editType == .add ? .appDescriptionAdd : .appDescriptionChange

        fetcher.publish(newWikidataDescription: description, from: descriptionSource, forWikidataID: wikiDataID, languageCode: articleLanguageCode, editTags: [editTag]) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let newRevisionID):
                completion(.success(ArticleDescriptionPublishResult(newRevisionID: newRevisionID, newDescription: description)))
            }
        }
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

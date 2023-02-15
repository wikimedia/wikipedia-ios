import Foundation
import WMF

struct ArticleDescriptionWarningTypes: OptionSet {
    let rawValue: Int

    static let length = ArticleDescriptionWarningTypes(rawValue: 1 << 0)
    static let casing = ArticleDescriptionWarningTypes(rawValue: 1 << 1)
}

struct ArticleDescriptionPublishResult {
    let newRevisionID: UInt64?
    let newDescription: String
}

protocol ArticleDescriptionControlling {
    var descriptionSource: ArticleDescriptionSource { get }
    var article: WMFArticle { get }
    var articleLanguageCode: String { get }
    func publishDescription(_ description: String, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void)
    func currentDescription(completion: @escaping (String?, MediaWikiAPIDisplayError?) -> Void)
    func errorCodeFromError(_ error: Error) -> String
    func learnMoreViewControllerWithTheme(_ theme: Theme) -> UIViewController?
    func warningTypesForDescription(_ description: String?) -> ArticleDescriptionWarningTypes
}

extension ArticleDescriptionControlling {
    var articleDisplayTitle: String? { return article.displayTitle }
    var descriptionMaxLength: Int { return 90 }
    
    func descriptionIsTooLong(_ description: String?) -> Bool {
        let isDescriptionLong = (description?.count ?? 0) > descriptionMaxLength
        return isDescriptionLong
    }
    
    func descriptionIsUppercase(_ description: String?) -> Bool {
        guard let firstCharacter = description?.first else {
          return false
        }
        
        return firstCharacter.isLetter && firstCharacter.isUppercase
    }
}

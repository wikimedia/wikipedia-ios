import Foundation

@objc public enum ArticleDescriptionSource: Int {
    case none
    case central
    case local
}

extension MWKArticle {
    public var descriptionSource: ArticleDescriptionSource {
        let value = descriptionSourceNumber?.intValue ?? 0
        return ArticleDescriptionSource(rawValue: value) ?? .none
    }
}

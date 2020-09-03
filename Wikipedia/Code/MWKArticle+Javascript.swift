
import Foundation

extension MWKArticle {
    public func apostropheEscapedArticleLanguageLocalizedStringForKey(_ key: String) -> String {
        return localizedStringForURLWithKeyFallingBackOnEnglish(url, key).wmf_stringByReplacingApostrophesWithBackslashApostrophes()
    }
}

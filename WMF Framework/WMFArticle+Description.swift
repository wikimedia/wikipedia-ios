import Foundation

extension WMFArticle {
    var wikidataDescriptionOrSnippet: String? {
        guard let wikidataDescription = wikidataDescription, wikidataDescription.characters.count > 0 else {
            return snippet
        }
        return wikidataDescription
    }
}

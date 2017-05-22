import Foundation

extension WMFArticle {
    public var capitalizedWikidataDescriptionOrSnippet: String? {
        guard let wikidataDescription = capitalizedWikidataDescription, wikidataDescription.characters.count > 0 else {
            return snippet
        }
        return wikidataDescription
    }
}

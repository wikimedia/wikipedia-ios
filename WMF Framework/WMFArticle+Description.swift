import Foundation

extension WMFArticle {
    @objc public var capitalizedWikidataDescriptionOrSnippet: String? {
        guard let wikidataDescription = capitalizedWikidataDescription, wikidataDescription.characters.count > 0 else {
            return snippet
        }
        return wikidataDescription
    }
}

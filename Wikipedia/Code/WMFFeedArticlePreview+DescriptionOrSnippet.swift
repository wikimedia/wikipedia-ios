
public extension WMFFeedArticlePreview {
    @objc var descriptionOrSnippet: String? {
        if let wikidataDescription = wikidataDescription, !wikidataDescription.isEmpty {
            let articleLanguage = articleURL.wmf_language
            return wikidataDescription.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: articleLanguage)
        }
        if let snippet = snippet, !snippet.isEmpty {
            return String(snippet.prefix(128))
        }
        return nil
    }
}

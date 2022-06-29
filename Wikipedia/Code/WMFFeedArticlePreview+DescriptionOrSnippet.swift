public extension WMFFeedArticlePreview {
    @objc var descriptionOrSnippet: String? {
        if let wikidataDescription = wikidataDescription, !wikidataDescription.isEmpty {
            let articleLanguageCode = articleURL.wmf_languageCode
            return wikidataDescription.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: articleLanguageCode)
        }
        if let snippet = snippet, !snippet.isEmpty {
            return String(snippet.prefix(128))
        }
        return nil
    }
}

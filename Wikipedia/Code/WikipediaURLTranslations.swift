
struct WikipediaURLTranslations {
    private static var sharedLookupTable = WikipediaURLTranslation(languageCode: "en").languagecode

    private static func updateLookupTableIfNecessary(for languageCode: String) {
        guard sharedLookupTable[languageCode] == nil else {
            return
        }
        let translationsForLanguageCode = WikipediaURLTranslation(languageCode: languageCode).languagecode
        sharedLookupTable.merge(translationsForLanguageCode) {(current, _) in current}
    }
    
    static func commonNamespace(for namespaceString: String, in languageCode: String) -> PageNamespace? {
        updateLookupTableIfNecessary(for: languageCode)
        return WikipediaURLTranslations.sharedLookupTable[languageCode]?.namespace[namespaceString.uppercased().replacingOccurrences(of: "_", with: " ")]
    }

    static func mainpage(in languageCode: String) -> String? {
        updateLookupTableIfNecessary(for: languageCode)
        return WikipediaURLTranslations.sharedLookupTable[languageCode]?.mainpage
    }
}

private struct WikipediaURLTranslation: Codable {
    var languagecode: Dictionary<String, WikipediaURLLanguageCodeTranslations> = Dictionary()
    init(languageCode: String) {
        guard
            let url = Bundle.main.url(forResource: "wikipedia-namespaces/\(languageCode)", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            assertionFailure("Unable to open JSON")
            return
        }
        do {
            languagecode = (try JSONDecoder().decode(WikipediaURLTranslation.self, from: data)).languagecode
        } catch {
            assertionFailure("Unable to decode WikipediaURLTranslation from JSON data")
        }
    }
}

private struct WikipediaURLLanguageCodeTranslations: Codable {
    let namespace: Dictionary<String, PageNamespace>
    let mainpage: String
}

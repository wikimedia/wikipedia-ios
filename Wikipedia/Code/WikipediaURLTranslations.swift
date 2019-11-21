
struct WikipediaURLTranslations {
    private static var sharedLookupTable: [String: WikipediaSiteInfoLookup] = [:]

    private static func lookupTable(for languageCode: String) -> WikipediaSiteInfoLookup? {
        var lookup = sharedLookupTable[languageCode]
        if lookup == nil {
            lookup = WikipediaSiteInfoLookup.fromFile(with: languageCode)
            sharedLookupTable[languageCode] = lookup
        }
        return lookup
    }

    static func commonNamespace(for namespaceString: String, in languageCode: String) -> PageNamespace? {
        let canonicalNamespace = namespaceString.uppercased().replacingOccurrences(of: "_", with: " ")
        return lookupTable(for: languageCode)?.namespace[canonicalNamespace]
    }
    
    static func mainpage(in languageCode: String) -> String? {
        return lookupTable(for: languageCode)?.mainpage
    }
}

private struct WikipediaSiteInfoLookup: Codable {
    let namespace: Dictionary<String, PageNamespace>
    let mainpage: String

    static func fromFile(with languageCode: String) -> WikipediaSiteInfoLookup? {
        guard
            let url = Bundle.main.url(forResource: "wikipedia-namespaces/\(languageCode)", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return try? JSONDecoder().decode(WikipediaSiteInfoLookup.self, from: data)
    }
}

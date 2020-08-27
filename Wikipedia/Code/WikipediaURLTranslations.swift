import Foundation

struct WikipediaURLTranslations {
    private static var sharedLookupTable: [String: WikipediaSiteInfoLookup] = [:]

    private static func lookupTable(for languageCode: String) -> WikipediaSiteInfoLookup? {
        var lookup = sharedLookupTable[languageCode]
        if lookup == nil {
            lookup = fromFile(with: languageCode)
            sharedLookupTable[languageCode] = lookup
        }
        return lookup
    }

    private static func canonicalized(_ string: String) -> String {
        return string.uppercased().replacingOccurrences(of: "_", with: " ")
    }
    
    static func commonNamespace(for namespaceString: String, in languageCode: String) -> PageNamespace? {
        let canonicalNamespace = canonicalized(namespaceString)
        return lookupTable(for: languageCode)?.namespace[canonicalNamespace]
    }
    
    static func isMainpageTitle(_ maybeMainpage: String, in languageCode: String) -> Bool {
        return lookupTable(for: languageCode)?.mainpage == canonicalized(maybeMainpage)
    }
    
    static func fromFile(with languageCode: String) -> WikipediaSiteInfoLookup? {
        guard
            let url = Bundle.wmf.url(forResource: "wikipedia-namespaces/\(languageCode)", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return try? JSONDecoder().decode(WikipediaSiteInfoLookup.self, from: data)
    }
}



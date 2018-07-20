public extension WMFContentGroupKind {
    private var offLanguageCodes: Set<String> {
        let preferredLangCodes = MWKLanguageLinkController.sharedInstance().preferredLanguages.map{$0.languageCode}
        return Set(preferredLangCodes).subtracting(languageCodes)
    }
    
    // codes define by: https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory
    var loggingCode: String {
        switch self {
        case .featuredArticle:
            return "fa"
        case .topRead:
            return "tr"
        case .onThisDay:
            return "od"
        case .news:
            return "ns"
        case .relatedPages:
            return "rp"
        case .continueReading:
            return "cr"
        case .location:
            return "pl"
        case .random:
            return "rd"
        case .pictureOfTheDay:
            return "pd"
        default:
            assertionFailure("Expected logging code not found")
            return ""
        }
    }
    
    // "on" / "off" define by: https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory
    var loggingLanguageInfo: [String: [String]] {
        var info = [String: [String]]()
        if languageCodes.count > 0 {
            info["on"] = Array(languageCodes)
        }
        if offLanguageCodes.count > 0 {
            info["off"] = Array(offLanguageCodes)
        }
        return info
    }
}

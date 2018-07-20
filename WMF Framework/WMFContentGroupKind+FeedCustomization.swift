public extension WMFContentGroupKind {
    var isInFeed: Bool {
        guard isGlobal else {
            return !feedContentController.languageCodes(for: self).isEmpty
        }
        return feedContentController.isGlobalContentGroupKind(inFeed: self)
    }

    var isCustomizable: Bool {
        return WMFExploreFeedContentController.customizableContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var isGlobal: Bool {
        return WMFExploreFeedContentController.globalContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var languageCodes: Set<String> {
        return feedContentController.languageCodes(for: self)
    }

    private var offLanguageCodes: Set<String> {
        let preferredLangCodes = MWKLanguageLinkController.sharedInstance().preferredLanguages.map{$0.languageCode}
        return Set(preferredLangCodes).subtracting(languageCodes)
    }
    
    private var feedContentController: WMFExploreFeedContentController {
        return SessionSingleton.sharedInstance().dataStore.feedContentController
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

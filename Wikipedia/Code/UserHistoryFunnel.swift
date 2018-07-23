// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

@objc final class UserHistoryFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private let targetCountries: [String] = [
        "US", "DE", "GB", "FR", "IT", "CA", "JP", "AU", "IN", "RU", "NL", "ES", "CH", "SE", "MX",
        "CN", "BR", "AT", "BE", "UA", "NO", "DK", "PL", "HK", "KR", "SA", "CZ", "IR", "IE", "SG",
        "NZ", "AE", "FI", "IL", "TH", "AR", "VN", "TW", "RO", "PH", "MY", "ID", "CL", "CO", "ZA",
        "PT", "HU", "GR", "EG"
    ]
    @objc public static let shared = UserHistoryFunnel()
    
    private var isTarget: Bool {
        guard let countryCode = Locale.current.regionCode else {
            return false
        }
        return targetCountries.contains(countryCode)
    }
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 18222579)
    }
    
    private func event() -> Dictionary<String, Any> {
        let userDefaults = UserDefaults.wmf_userDefaults()
        
        let fontSize = userDefaults.wmf_articleFontSizeMultiplier().intValue
        let theme = userDefaults.wmf_appTheme.displayName.lowercased()
        let isFeedDisabled = userDefaults.defaultTabType != .explore
        let isNewsNotificationEnabled = userDefaults.wmf_inTheNewsNotificationsEnabled()
        let appOpensOnSearchTab = userDefaults.wmf_openAppOnSearchTab

        var event: [String: Any] = ["primary_language": primaryLanguage(), "is_anon": isAnon, "measure_font_size": fontSize, "theme": theme, "feed_disabled": isFeedDisabled, "trend_notify": isNewsNotificationEnabled, "search_tab": appOpensOnSearchTab]

        guard let dataStore = SessionSingleton.sharedInstance().dataStore else {
            return event
        }
        
        let savedArticlesCount = dataStore.savedPageList.numberOfItems()
        event["measure_readinglist_itemcount"] = savedArticlesCount
        
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        event["readinglist_sync"] = isSyncEnabled
        event["readinglist_showdefault"] = isDefaultListEnabled
        
        if let readingListCount = try? dataStore.viewContext.allReadingListsCount() {
            event["measure_readinglist_listcount"] = readingListCount
        }

        var feedEnabledList = [String: Any]()
        [WMFContentGroupKind.featuredArticle, WMFContentGroupKind.topRead, WMFContentGroupKind.onThisDay, WMFContentGroupKind.news, WMFContentGroupKind.relatedPages, WMFContentGroupKind.continueReading, WMFContentGroupKind.location, WMFContentGroupKind.random, WMFContentGroupKind.pictureOfTheDay].forEach({contentGroupKind in
            let loggingCode = contentGroupKind.loggingCode
            if contentGroupKind.isGlobal {
                feedEnabledList[loggingCode] = contentGroupKind.isInFeed
            } else {
                feedEnabledList[loggingCode] = contentGroupKind.loggingLanguageInfo
            }
        })
        event["feed_enabled_list"] = feedEnabledList
        
        return wholeEvent(with: event)
    }
    
    override func logged(_ eventData: [AnyHashable: Any]) {
        guard let eventData = eventData as? [String: Any] else {
            return
        }
        EventLoggingService.shared.lastLoggedSnapshot = eventData as NSCoding
    }
    
    private var latestSnapshot: Dictionary<String, Any>? {
        return EventLoggingService.shared.lastLoggedSnapshot as? Dictionary<String, Any>
    }
    
    @objc public func logSnapshot() {
        guard let latestSnapshot = latestSnapshot else {
            return
        }
        guard isTarget else {
            return
        }
        
        let newSnapshot = event()
        
        guard !newSnapshot.wmf_isEqualTo(latestSnapshot, excluding: standardEvent.keys) else {
            // DDLogDebug("User History snapshots are identical; logging new User History snapshot aborted")
            return
        }
        
        // DDLogDebug("User History snapshots are different; logging new User History snapshot")
        log(event())
    }
    
    @objc public func logStartingSnapshot() {
        guard latestSnapshot == nil else {
            // DDLogDebug("Starting User History snapshot was already recorded; logging new User History snapshot aborted")
            return
        }
        guard isTarget else {
            return
        }
        log(event())
        // DDLogDebug("Attempted to log starting User History snapshot")
    }
}

private extension WMFContentGroupKind {
    var offLanguageCodes: Set<String> {
        let preferredLangCodes = MWKLanguageLinkController.sharedInstance().preferredLanguages.map{$0.languageCode}
        return Set(preferredLangCodes).subtracting(languageCodes)
    }
    
    // codes define by: https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory
    var userHistorySchemaCode: String? {
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
            return nil
        }
    }
    
    // "on" / "off" define by: https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory
    var userHistorySchemaLanguageInfo: [String: [String]] {
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

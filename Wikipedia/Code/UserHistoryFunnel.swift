// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

private typealias ContentGroupKindAndLoggingCode = (kind: WMFContentGroupKind, loggingCode: String)

@objc final class UserHistoryFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private let targetCountries: Set<String> = Set<String>(arrayLiteral:
        "US", "DE", "GB", "FR", "IT", "CA", "JP", "AU", "IN", "RU", "NL", "ES", "CH", "SE", "MX",
        "CN", "BR", "AT", "BE", "UA", "NO", "DK", "PL", "HK", "KR", "SA", "CZ", "IR", "IE", "SG",
        "NZ", "AE", "FI", "IL", "TH", "AR", "VN", "TW", "RO", "PH", "MY", "ID", "CL", "CO", "ZA",
        "PT", "HU", "GR", "EG"
    )
    @objc public static let shared = UserHistoryFunnel(dataStore: MWKDataStore.shared())
    
    private var isTarget: Bool {
        guard let countryCode = Locale.current.regionCode?.uppercased() else {
            return false
        }
        return targetCountries.contains(countryCode)
    }
    
    let dataStore: MWKDataStore
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 20339865)
    }
    
    private func event() -> Dictionary<String, Any> {
        let userDefaults = UserDefaults.standard
        
        let fontSize = UserDefaults.standard.wmf_articleFontSizeMultiplier().intValue
        let theme = userDefaults.themeAnalyticsName
        let isFeedDisabled = userDefaults.defaultTabType != .explore
        let isNewsNotificationEnabled = UserDefaults.standard.wmf_inTheNewsNotificationsEnabled()
        let appOpensOnSearchTab = UserDefaults.standard.wmf_openAppOnSearchTab

        var event: [String: Any] = ["primary_language": primaryLanguage(), "is_anon": isAnon, "measure_font_size": fontSize, "theme": theme, "feed_disabled": isFeedDisabled, "trend_notify": isNewsNotificationEnabled, "search_tab": appOpensOnSearchTab]
        
        let savedArticlesCount = dataStore.savedPageList.numberOfItems()
        event["measure_readinglist_itemcount"] = savedArticlesCount
        
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        event["readinglist_sync"] = isSyncEnabled
        event["readinglist_showdefault"] = isDefaultListEnabled
        
        if let readingListCount = try? dataStore.viewContext.allReadingListsCount() {
            event["measure_readinglist_listcount"] = readingListCount
        }

        event["feed_enabled_list"] = feedEnabledListPayload()
        
        if let articleAsLivingDocBucket = dataStore.abTestsController.bucketForExperiment(.articleAsLivingDoc) {
            event["test_group"] = articleAsLivingDocBucket.rawValue
        }
        
        return wholeEvent(with: event)
    }
    
    private func feedEnabledListPayload() -> [String: Any] {
        let contentGroupKindAndLoggingCodeFromNumber:(NSNumber) -> ContentGroupKindAndLoggingCode? = { kindNumber in
            // The MobileWikiAppiOSUserHistory schema only specifies that we log certain card types for `feed_enabled_list`.
            // If `userHistorySchemaCode` returns nil for a given WMFContentGroupKind we don't add an entry to `feed_enabled_list`.
            guard let kind = WMFContentGroupKind(rawValue: kindNumber.int32Value), let loggingCode = kind.userHistorySchemaCode else {
                return nil
            }
            return (kind: kind, loggingCode: loggingCode)
        }
        
        var feedEnabledList = [String: Any]()
        
        WMFExploreFeedContentController.globalContentGroupKindNumbers().compactMap(contentGroupKindAndLoggingCodeFromNumber).forEach() {
            feedEnabledList[$0.loggingCode] = $0.kind.isInFeed
        }
        
        WMFExploreFeedContentController.customizableContentGroupKindNumbers().compactMap(contentGroupKindAndLoggingCodeFromNumber).forEach() {
            feedEnabledList[$0.loggingCode] = $0.kind.userHistorySchemaLanguageInfo
        }

        return feedEnabledList
    }
    
    override func logged(_ eventData: [AnyHashable: Any]) {
        guard let eventData = eventData as? [String: Any] else {
            return
        }
        EventLoggingService.shared?.lastLoggedSnapshot = eventData as NSCoding
        UserDefaults.standard.wmf_lastAppVersion = WikipediaAppUtils.appVersion()
    }
    
    private var latestSnapshot: Dictionary<String, Any>? {
        return EventLoggingService.shared?.lastLoggedSnapshot as? Dictionary<String, Any>
    }
    
    @objc public func logSnapshot() {
        guard EventLoggingService.shared?.isEnabled ?? false else {
            return
        }
        
        guard isTarget else {
            return
        }
        
        guard let lastAppVersion = UserDefaults.standard.wmf_lastAppVersion else {
            log(event())
            return
        }
        guard let latestSnapshot = latestSnapshot else {
            return
        }

        let newSnapshot = event()
        
        guard !newSnapshot.wmf_isEqualTo(latestSnapshot, excluding: standardEvent.keys) || lastAppVersion != WikipediaAppUtils.appVersion() else {
            // DDLogDebug("User History snapshots are identical; logging new User History snapshot aborted")
            return
        }
        
        // DDLogDebug("User History snapshots are different; logging new User History snapshot")
        log(event())
    }
    
    @objc public func logStartingSnapshot() {
        guard latestSnapshot == nil else {
            // DDLogDebug("Starting User History snapshot was already recorded; logging new User History snapshot aborted")
            logSnapshot() // call standard log snapshot in case version changed, should be logged on session start
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
        let preferredContentLangCodes = MWKDataStore.shared().languageLinkController.preferredLanguages.map{$0.contentLanguageCode}
        return Set(preferredContentLangCodes).subtracting(contentLanguageCodes)
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
        if !contentLanguageCodes.isEmpty {
            info["on"] = Array(contentLanguageCodes)
        }
        if !offLanguageCodes.isEmpty {
            info["off"] = Array(offLanguageCodes)
        }
        return info
    }
}

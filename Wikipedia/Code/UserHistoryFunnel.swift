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
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 17990229)
    }
    
    private func event() -> Dictionary<String, Any> {
        let userDefaults = UserDefaults.wmf_userDefaults()
        
        let fontSize = userDefaults.wmf_articleFontSizeMultiplier().intValue
        let theme = userDefaults.wmf_appTheme.displayName.lowercased()
        
        var event: [String: Any] = ["primary_language": primaryLanguage(), "is_anon": isAnon, "measure_font_size": fontSize, "theme": theme]
        
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

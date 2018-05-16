// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

@objc final class UserHistoryFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = UserHistoryFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 17990229)
    }
    
    private func event() -> Dictionary<String, Any> {
        let userDefaults = UserDefaults.wmf_userDefaults()
        
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let fontSize = userDefaults.wmf_articleFontSizeMultiplier().intValue
        let theme = userDefaults.wmf_appTheme.displayName.lowercased()
        
        var event: [String: Any] = ["primary_language": primaryLanguage, "is_anon": isAnon, "measure_font_size": fontSize, "theme": theme]
        
        guard let dataStore = SessionSingleton.sharedInstance().dataStore else {
            return event
        }
        
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        event["readinglist_sync"] = isSyncEnabled
        event["readinglist_showdefault"] = isDefaultListEnabled
        
        if let readingListCount = try? dataStore.viewContext.allReadingListsCount() {
            event["measure_readinglist_listcount"] = readingListCount
        }
        if let savedArticlesCount = try? dataStore.viewContext.allSavedArticlesCount() {
            event["measure_readinglist_itemcount"] = savedArticlesCount
        }
        
        return wholeEvent(with: event)
    }
    
    override func logged(_ eventData: [AnyHashable: Any]) {
        guard let eventData = eventData as? [String: Any] else {
            return
        }
        UserDefaults.wmf_userDefaults().wmf_lastLoggedUserHistorySnapshot = eventData
    }
    
    private var latestSnapshot: Dictionary<String, Any>? {
        return UserDefaults.wmf_userDefaults().wmf_lastLoggedUserHistorySnapshot
    }
    
    @objc public func logSnapshot() {
        guard let latestSnapshot = latestSnapshot else {
            assertionFailure("User History snapshot must have a value")
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
        log(event())
        // DDLogDebug("Attempted to log starting User History snapshot")
    }
}

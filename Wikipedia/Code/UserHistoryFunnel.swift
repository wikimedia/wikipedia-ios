// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

@objc class UserHistoryFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private let dataStore: MWKDataStore
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 17990229)
    }
    
    private func event() -> Dictionary<String, Any> {
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        let fontSize = UserDefaults.wmf_userDefaults().wmf_articleFontSizeMultiplier().intValue
        let theme = UserDefaults.wmf_userDefaults().wmf_appTheme.displayName.lowercased()
        
        var event: [String: Any] = ["readinglist_sync": isSyncEnabled, "readinglist_showdefault": isDefaultListEnabled, "primary_language": primaryLanguage, "is_anon": isAnon, "measure_font_size": fontSize, "theme": theme]
        if let readingListCount = try? dataStore.viewContext.allReadingListsCount() {
            event["measure_readinglist_listcount"] = readingListCount
        }
        if let savedArticlesCount = try? dataStore.viewContext.allSavedArticlesCount() {
            event["measure_readinglist_itemcount"] = savedArticlesCount
        }
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: event())
    }
    
    override func logged(_ eventData: [AnyHashable: Any]) {
        guard let eventData = eventData as? [String: Any] else {
            return
        }
        UserDefaults.wmf_userDefaults().wmf_lastLoggedUserHistorySnapshot = eventData
    }
    
    @objc public func logSnapshot() {
        guard let latestSnapshot = UserDefaults.wmf_userDefaults().wmf_lastLoggedUserHistorySnapshot else {
            assertionFailure("User History snapshot must have value")
            return
        }
        
        let newSnapshot = event()

        guard !newSnapshot.wmf_isEqualTo(latestSnapshot, excluding: standardEvent.keys) else {
            DDLogDebug("User History snapshots are identical; logging new User History snapshot aborted")
            return
        }
        
        DDLogDebug("User History snapshots are different; logging new User History snapshot")
        log(standardEvent)
    }
    
    @objc public func logStartingSnapshot() {
        guard latestSnapshot == nil else {
            DDLogDebug("Starting User History snapshot was already recorded; logging new User History snapshot aborted")
            return
        }
        log(standardEvent)
        DDLogDebug("Attempted to log starting User History snapshot")
    }
}

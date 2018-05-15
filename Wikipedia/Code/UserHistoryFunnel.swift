// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

@objc(UserHistoryFunnel)
class UserHistoryFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private let dataStore: MWKDataStore
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 17990229)
    }
    
    private func event() throws -> Dictionary<String, Any> {
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let readingListCount = try dataStore.viewContext.allReadingListsCount()
        let savedArticlesCount = try dataStore.viewContext.allSavedArticlesCount()
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        let fontSize = UserDefaults.wmf_userDefaults().wmf_articleFontSizeMultiplier().intValue
        let theme = UserDefaults.wmf_userDefaults().wmf_appTheme.displayName.lowercased()
        
        let event: [String: Any] = [ "measure_readinglist_listcount": readingListCount, "measure_readinglist_itemcount": savedArticlesCount, "readinglist_sync": isSyncEnabled, "readinglist_showdefault": isDefaultListEnabled, "primary_language": primaryLanguage, "is_anon": isAnon, "measure_font_size": fontSize, "theme": theme]
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable : Any]) -> [AnyHashable : Any] {
        guard let event = try? eventData.merging(event(), uniquingKeysWith: { (first, _) in first }) else {
            DDLogError("Error logging User History snapshot")
            return [:]
        }
        return event
    }
    
    override func logged(_ eventData: [AnyHashable: Any]) {
        guard let eventData = eventData as? [String: Any] else {
            return
        }
        UserDefaults.wmf_userDefaults().wmf_lastLoggedUserHistorySnapshot = eventData
    }
    
    @objc public func logSnapshot() {
        guard let latestSnapshot = UserDefaults.wmf_userDefaults().wmf_lastLoggedUserHistorySnapshot, let newSnapshot = try? event() else {
            assertionFailure("User History snapshots must have values")
            return
        }

        guard !newSnapshot.wmf_isEqualTo(latestSnapshot, excluding: standardEvent.keys) else {
            DDLogDebug("User History snapshots are identical; logging new User History snapshot aborted")
            return
        }
        
        DDLogDebug("User History snapshots are different; logging new User History snapshot")
        log(standardEvent)
    }
    
    @objc public func logStartingSnapshot() {
        log(standardEvent)
        DDLogDebug("Attempted to log starting User History snapshot")
    }
}

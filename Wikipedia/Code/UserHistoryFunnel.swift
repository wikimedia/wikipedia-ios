// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

@objc(UserHistoryFunnel)
class UserHistoryFunnel: EventLoggingFunnel {
    private let dataStore: MWKDataStore
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(schema: "MobileWikiAppiOSUserHistory", version: 17990229)
    }
    
    private func event() throws -> Dictionary<String, Any> {
        let appInstallID = wmf_appInstallID()
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let timestamp = DateFormatter.wmf_iso8601().string(from: Date())
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let sessionID = wmf_sessionID()
        let readingListCount = try dataStore.viewContext.allReadingListsCount()
        let savedArticlesCount = try dataStore.viewContext.allSavedArticlesCount()
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        
        let event: [String: Any] = ["app_install_id": appInstallID, "measure_readinglist_listcount": readingListCount, "measure_readinglist_itemcount": savedArticlesCount, "readinglist_sync": isSyncEnabled, "readinglist_showdefault": isDefaultListEnabled, "primary_language": primaryLanguage, "is_anon": isAnon, "event_dt": timestamp, "session_id": sessionID]
        return event
    }
    
    @objc public func logSnapshot() {
        do {
         try log(event())
        } catch let error {
            DDLogError("Error logging User History snapshot: \(error)")
        }
    }
}

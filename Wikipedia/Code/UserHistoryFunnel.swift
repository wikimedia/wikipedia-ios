// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSUserHistory

@objc(UserHistoryFunnel)
class UserHistoryFunnel: EventLoggingFunnel, EventLoggingStandardEventDataProviding {
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
        
        let standardEvent = standardEventData
        let newEvent: [String: Any] = [ "measure_readinglist_listcount": readingListCount, "measure_readinglist_itemcount": savedArticlesCount, "readinglist_sync": isSyncEnabled, "readinglist_showdefault": isDefaultListEnabled, "primary_language": primaryLanguage, "is_anon": isAnon]
        let event = standardEvent.merging(newEvent, uniquingKeysWith: { (first, _) in first })
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

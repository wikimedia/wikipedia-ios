private typealias ContentGroupKindAndLoggingCode = (kind: WMFContentGroupKind, loggingCode: String)

@objc public final class UserHistoryFunnel: NSObject {
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
    }

    private let sharedCache = SharedContainerCache<UserHistorySnapshotCache>.init(fileName: "User History Funnel Snapshot", defaultCache: {
        UserHistorySnapshotCache(snapshot: UserHistoryFunnel.Event(measure_readinglist_listcount: nil, measure_readinglist_itemcount: nil, measure_font_size: nil, readinglist_sync: nil, readinglist_showdefault: nil, theme: nil, feed_disabled: nil, search_tab: nil, feed_enabled_list: nil, inbox_count: nil, device_level_enabled: nil))
    })

    public struct FeedEnabledList: Codable, Equatable {
        let featuredArticle: ItemLanguages?
        let topRead: ItemLanguages?
        let onThisDay: ItemLanguages?
        let inTheNews: ItemLanguages?
        let places: ItemLanguages?
        let randomizer: ItemLanguages?
        let relatedPages: Bool?
        let continueReading: Bool?
        let pictureOfTheDay: Bool?

        enum CodingKeys: String, CodingKey {
            case featuredArticle = "fa"
            case topRead = "tr"
            case onThisDay = "od"
            case inTheNews = "ns"
            case places = "pl"
            case randomizer = "rd"
            case relatedPages  = "rp"
            case continueReading = "cr"
            case pictureOfTheDay = "pd"
        }

        public static func == (lhs: UserHistoryFunnel.FeedEnabledList, rhs: UserHistoryFunnel.FeedEnabledList) -> Bool {
            return lhs.featuredArticle == rhs.featuredArticle
            && lhs.topRead == rhs.topRead
            && lhs.onThisDay == rhs.onThisDay
            && lhs.inTheNews == rhs.inTheNews
            && lhs.places == rhs.places
            && lhs.randomizer == rhs.randomizer
            && lhs.relatedPages == rhs.relatedPages
            && lhs.continueReading == rhs.continueReading
            && lhs.pictureOfTheDay == rhs.pictureOfTheDay
        }
    }

    public struct ItemLanguages: Codable, Equatable {
        let on: [String]?
        let off: [String]?
    }

    public struct Event: EventInterface, Equatable {
        public static let schema: EventPlatformClient.Schema = .userHistory
        let measure_readinglist_listcount: Int?
        let measure_readinglist_itemcount: Int?
        let measure_font_size: Int?
        let readinglist_sync: Bool?
        let readinglist_showdefault: Bool?
        let theme: String?
        let feed_disabled: Bool?
        let search_tab: Bool?
        let feed_enabled_list: FeedEnabledList?
        let inbox_count: Int?
        let device_level_enabled: String?

        public static func == (lhs: UserHistoryFunnel.Event, rhs: UserHistoryFunnel.Event) -> Bool {
            return lhs.measure_readinglist_listcount == lhs.measure_readinglist_listcount
            && lhs.measure_readinglist_itemcount == rhs.measure_readinglist_itemcount
            && lhs.measure_font_size == rhs.measure_font_size
            && lhs.readinglist_sync == rhs.readinglist_sync
            && lhs.readinglist_showdefault == rhs.readinglist_showdefault
            && lhs.theme == rhs.theme
            && lhs.feed_disabled == rhs.feed_disabled
            && lhs.feed_enabled_list == rhs.feed_enabled_list
            && lhs.inbox_count == rhs.inbox_count
            && lhs.device_level_enabled == rhs.device_level_enabled
        }
    }


    private func getLanguagesForItemInFeed(code: String?) -> ItemLanguages? {
        guard let code else { return nil }
        let itemNumber = getUserHistorySchemaNumber(code: code)
        if let itemNumber {
            let kind = WMFContentGroupKind(rawValue: Int32(itemNumber))
            if let kind, kind.isInFeed {
                return ItemLanguages(on: Array(kind.contentLanguageCodes), off: Array(kind.offLanguageCodes))
            }
            return nil
        }
        return nil
    }

    private func getItemInFeed(code: String?) -> Bool? {
        guard let code else { return false }
        let itemNumber = getUserHistorySchemaNumber(code: code)
        if let itemNumber {
            let kind = WMFContentGroupKind(rawValue: Int32(itemNumber))
            if let kind, kind.isInFeed {
                return true
            }
            return false
        }
        return false
    }

    private func getFeedEnabledList() -> FeedEnabledList? {
        let feedItem = FeedEnabledList(
            featuredArticle: getLanguagesForItemInFeed(code: "fa"),
            topRead: getLanguagesForItemInFeed(code: "tr"),
            onThisDay: getLanguagesForItemInFeed(code: "od"),
            inTheNews: getLanguagesForItemInFeed(code: "ns"),
            places: getLanguagesForItemInFeed(code: "pl"),
            randomizer: getLanguagesForItemInFeed(code: "rd"),
            relatedPages: getItemInFeed(code: "rp"),
            continueReading: getItemInFeed(code: "cr"),
            pictureOfTheDay: getItemInFeed(code: "pd"))
        return feedItem
    }

    @discardableResult
    private func logEvent(authorizationStatus: UNAuthorizationStatus?) -> Event {
        let userDefaults = UserDefaults.standard
        let theme = userDefaults.themeAnalyticsName
        let isFeedDisabled = userDefaults.defaultTabType != .explore
        let appOpensOnSearchTab = UserDefaults.standard.wmf_openAppOnSearchTab
        let inboxCount = try? dataStore.remoteNotificationsController.numberOfAllNotifications()
        let fontSize = UserDefaults.standard.wmf_articleFontSizeMultiplier().intValue
        let savedArticlesCount = dataStore.savedPageList.numberOfItems()
        let isSyncEnabled = dataStore.readingListsController.isSyncEnabled
        let isDefaultListEnabled = dataStore.readingListsController.isDefaultListEnabled
        let readingListCount = try? dataStore.viewContext.allReadingListsCount()
        let status = authorizationStatus?.getAuthorizationStatusString()

        let event = Event(measure_readinglist_listcount: savedArticlesCount, measure_readinglist_itemcount: readingListCount, measure_font_size: fontSize, readinglist_sync: isSyncEnabled, readinglist_showdefault: isDefaultListEnabled, theme: theme, feed_disabled: isFeedDisabled, search_tab: appOpensOnSearchTab, feed_enabled_list: getFeedEnabledList(), inbox_count: inboxCount, device_level_enabled: status)
        EventPlatformClient.shared.submit(stream: .userHistory, event: event)
        return event
    }
    
    private var latestSnapshot: Event? {
        return sharedCache.loadCache().snapshot
    }
    
    @objc public func logSnapshot() {
        guard EventPlatformClient.shared.isEnabled else {
            return
        }
        
        guard isTarget else {
            return
        }

        var cache = self.sharedCache.loadCache()

        dataStore.notificationsController.notificationPermissionsStatus { [weak self] authorizationStatus in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                guard let lastAppVersion = UserDefaults.standard.wmf_lastAppVersion else {
                    self.logEvent(authorizationStatus: authorizationStatus)
                    return
                }
                guard let latestSnapshot = self.latestSnapshot else {
                    return
                }
                
                let newSnapshot = self.logEvent(authorizationStatus: authorizationStatus)

                guard !(newSnapshot == latestSnapshot) || lastAppVersion != WikipediaAppUtils.appVersion() else {
                    return
                }
                let events = self.logEvent(authorizationStatus: authorizationStatus)

                cache.snapshot = events
                self.sharedCache.saveCache(cache)
            }
        }
    }
    
    @objc public func logStartingSnapshot() {
        guard latestSnapshot == nil else {
            logSnapshot()
            return
        }
        guard isTarget else {
            return
        }
        dataStore.notificationsController.notificationPermissionsStatus { [weak self] authorizationStatus in
            
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async {
                self.logEvent(authorizationStatus: authorizationStatus)
            }
        }
    }
}

extension UserHistoryFunnel {
    func getUserHistorySchemaNumber(code: String) -> Int? {
        switch code {
        case "fa":
            return 7
        case "tr":
            return 8
        case "od":
            return 13
        case "ns":
            return 9
        case "rp":
            return 3
        case "cr":
            return 1
        case "pl":
            return 4
        case "rd":
            return 6
        case "pd":
            return 5
        default:
            return nil
        }
    }

}

private extension WMFContentGroupKind {
    var offLanguageCodes: Set<String> {
        let preferredContentLangCodes = MWKDataStore.shared().languageLinkController.preferredLanguages.map {$0.contentLanguageCode}
        return Set(preferredContentLangCodes).subtracting(contentLanguageCodes)
    }

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


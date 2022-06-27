import Foundation

@objc(WMFNavigationEventsFunnel)
final class NavigationEventsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    enum Action: String, Codable {
        case explore
        case places
        case saved
        case savedAll = "saved_all"
        case savedLists = "saved_lists"
        case history
        case search
        case settingsOpenNav = "setting_open_nav"
        case settingsOpenExplore = "setting_open_explore"
        case settingsAccount = "setting_account"
        case settingsClose = "setting_close"
        case settingsFundraise = "setting_fundraise"
        case settingsLanguages = "setting_languages"
        case settingsSearch = "setting_search"
        case settingsExploreFeed = "setting_explorefeed"
        case settingsNotifications = "setting_notifications"
        case settingsReadPrefs = "setting_read_prefs"
        case settingsStorageSync = "setting_storagesync"
        case settingsReadDanger = "setting_read_danger"
        case settingsClearData = "setting_cleardata"
        case settingsPrivacy = "setting_privacy"
        case settingsTOS = "setting_tos"
        case settingsUsageReports = "setting_usage_reports"
        case settingsRate = "setting_rate"
        case settingsHelp = "setting_help"
        case settingsAbout = "setting_about"
    }
    
    @objc static let shared = NavigationEventsFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSNavigationEvents", version: 21426269)
    }
    
    private func event(action: Action) -> [String: Any] {
        let event: [String: Any] = ["action": action.rawValue, "primary_language": primaryLanguage(), "is_anon": isAnon]
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    @objc func logTappedExplore() {
        log(event(action: .explore))
    }
    
    @objc func logTappedPlaces() {
        log(event(action: .places))
    }
    
    @objc func logTappedSaved() {
        log(event(action: .saved))
    }
    
    @objc func logTappedHistory() {
        log(event(action: .history))
    }
    
    @objc func logTappedSearch() {
        log(event(action: .search))
    }
    
    @objc func logTappedSettingsFromTabBar() {
        log(event(action: .settingsOpenNav))
    }
    
    @objc func logTappedSettingsFromExplore() {
        log(event(action: .settingsOpenExplore))
    }
    
    func logTappedSavedAllArticles() {
        log(event(action: .savedAll))
    }
    
    func logTappedSavedReadingLists() {
        log(event(action: .savedLists))
    }
    
    @objc func logTappedSettingsCloseButton() {
        log(event(action: .settingsClose))
    }
    
    @objc func logTappedSettingsLoginLogout() {
        log(event(action: .settingsAccount))
    }
    
    @objc func logTappedSettingsSupportWikipedia() {
        log(event(action: .settingsFundraise))
    }
    
    @objc func logTappedSettingsLanguages() {
        log(event(action: .settingsLanguages))
    }
    
    @objc func logTappedSettingsSearch() {
        log(event(action: .settingsSearch))
    }
    
    @objc func logTappedSettingsExploreFeed() {
        log(event(action: .settingsExploreFeed))
    }
    
    @objc func logTappedSettingsNotifications() {
        log(event(action: .settingsNotifications))
    }
    
    @objc func logTappedSettingsReadingPreferences() {
        log(event(action: .settingsReadPrefs))
    }
    
    @objc func logTappedSettingsArticleStorageAndSyncing() {
        log(event(action: .settingsStorageSync))
    }
    
    @objc func logTappedSettingsReadingListDangerZone() {
        log(event(action: .settingsReadDanger))
    }
    
    @objc func logTappedSettingsClearCachedData() {
        log(event(action: .settingsClearData))
    }
    
    @objc func logTappedSettingsPrivacyPolicy() {
        log(event(action: .settingsPrivacy))
    }
    
    @objc func logTappedSettingsTermsOfUse() {
        log(event(action: .settingsTOS))
    }
    
    @objc func logTappedSettingsSendUsageReports() {
        log(event(action: .settingsUsageReports))
    }
    
    @objc func logTappedSettingsRateTheApp() {
        log(event(action: .settingsRate))
    }
    
    @objc func logTappedSettingsHelp() {
        log(event(action: .settingsHelp))
    }
    
    @objc func logTappedSettingsAbout() {
        log(event(action: .settingsAbout))
    }
}

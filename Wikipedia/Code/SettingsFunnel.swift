class SettingsFunnel: EventLoggingFunnel {
    
    private enum Action: String {
        case impression
        case sync
        case unsync
    }
    
    override init() {
        super.init(schema: "MobileWikiAppiOSSettingAction", version: 17990226)
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action) -> Dictionary<String, Any> {
        guard category != .undefined else {
            assertionFailure("category cannot be undefined")
            return [:]
        }
        
        let appInstallID = wmf_appInstallID()
        let category = category.rawValue
        let action = action.rawValue
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let timestamp = String(describing: NSDate()).wmf_iso8601Date
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let sessionID = wmf_sessionID()
        
        var event: [String: Any] = ["app_install_id": appInstallID, "category": category, "action": action, "primary_language": primaryLanguage, "is_anon": isAnon, "event_dt": timestamp, "session_id": sessionID]
        if let label = label {
            event["label"] = label.rawValue
        }
        
        return event
    }
    
    public func logSyncEnabledInSettings() {
        log(event(category: .setting, label: .syncArticle, action: .sync))
    }
    
    public func logSyncDisabledInSettings() {
        log(event(category: .setting, label: .syncArticle, action: .unsync))
    }
    
    public func logEnableSyncPopoverImpression() {
        log(event(category: .enableSyncPopover, label: nil, action: .impression))
    }
    
    public func logEnableSyncPopoverSyncEnabled() {
        log(event(category: .enableSyncPopover, label: nil, action: .sync))
    }
}

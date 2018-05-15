// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSettingAction

class SettingsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
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
        
        let category = category.rawValue
        let action = action.rawValue
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage, "is_anon": isAnon]
        if let label = label {
            event["label"] = label.rawValue
        }
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
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

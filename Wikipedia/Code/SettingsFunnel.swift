// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSettingAction

class SettingsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = SettingsFunnel()
    
    private enum Action: String {
        case impression
        case sync
        case unsync
    }
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSSettingAction", version: 18064085)
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action) -> Dictionary<String, Any> {
        let category = category.rawValue
        let action = action.rawValue
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage(), "is_anon": isAnon]
        if let label = label?.rawValue {
            event["label"] = label
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

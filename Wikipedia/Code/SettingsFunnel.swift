@objc class SettingsFunnel: NSObject {
    @objc public static let shared = SettingsFunnel()
    
    private enum Action: String, Codable {
        case impression
        case sync
        case unsync
    }

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .settings
        let action: Action
        let category: EventCategoryMEP
        let label: EventLabelMEP?
    }

    private func logEvent(category: EventCategoryMEP, label: EventLabelMEP?, action: Action) {
        let event = SettingsFunnel.Event(action: action, category: category, label: label)
        EventPlatformClient.shared.submit(stream: .settings, event: event)
    }

    public func logSyncEnabledInSettings() {
        logEvent(category: .setting, label: .syncArticle, action: .sync)
    }
    
    public func logSyncDisabledInSettings() {
        logEvent(category: .setting, label: .syncArticle, action: .unsync)
    }
    
    public func logEnableSyncPopoverImpression() {
        logEvent(category: .enableSyncPopover, label: nil, action: .impression)
    }
    
    public func logEnableSyncPopoverSyncEnabled() {
        logEvent(category: .enableSyncPopover, label: nil, action: .sync)
    }
}

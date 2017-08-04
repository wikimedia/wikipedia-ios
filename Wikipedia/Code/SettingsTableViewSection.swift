@objc(WMFSettingsTableViewSection)
class SettingsTableViewSection: NSObject {
    let headerTitle: String?
    let footerText: String?
    let items: [WMFSettingsTableViewCell]
    
    init(items: [WMFSettingsTableViewCell], headerTitle: String?, footerText: String?) {
        self.items = items
        self.headerTitle = headerTitle
        self.footerText = footerText
    }
    
    func getItems() -> [WMFSettingsTableViewCell] {
        return self.items
    }
    
    func getHeaderTitle() -> String? {
        return self.headerTitle
    }
}

@objc(WMFSettingsTableViewSection)
class SettingsTableViewSection: NSObject {
    @objc let headerTitle: String?
    @objc let footerText: String?
    @objc let items: [WMFSettingsMenuItem]
    
    @objc init(items: [WMFSettingsMenuItem], headerTitle: String?, footerText: String?) {
        self.items = items
        self.headerTitle = headerTitle
        self.footerText = footerText
    }
    
    @objc func getItems() -> [WMFSettingsMenuItem] {
        return self.items
    }
    
    @objc func getHeaderTitle() -> String? {
        return self.headerTitle
    }
}

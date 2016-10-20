import UIKit


protocol NotificationSettingsItem {
    var title: String { get }
}

struct NotificationSettingsSwitchItem: NotificationSettingsItem {
    let title: String
    let switchChecker: () -> Bool
    let switchAction: (Bool) -> Void
}

struct NotificationSettingsButtonItem: NotificationSettingsItem {
    let title: String
    let buttonAction: () -> Void
}

struct NotificationSettingsSection {
    let headerTitle:String
    let items: [NotificationSettingsItem]
}

class NotificationSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    
    var sections = [NotificationSettingsSection]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.delegate = self
        tableView.dataSource = self
        updateSections()
    }
    
    func updateSections() {
        var updatedSections = [NotificationSettingsSection]()
        
        let notificationSettingsItems: [NotificationSettingsItem] = [NotificationSettingsSwitchItem(title: localizedStringForKeyFallingBackOnEnglish("settings-notifications-trending"), switchChecker: { () -> Bool in
            return true
            }, switchAction: { (isOn) in
            
        })]
        let notificationSettingsSection = NotificationSettingsSection(headerTitle: localizedStringForKeyFallingBackOnEnglish("settings-notifications-push-notifications"), items: notificationSettingsItems)
        
        updatedSections.append(notificationSettingsSection)
        sections = updatedSections
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(WMFSettingsTableViewCell.identifier(), forIndexPath: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        let item = sections[indexPath.section].items[indexPath.item]
        cell.title = item.title
        
        if let switchItem = item as? NotificationSettingsSwitchItem {
            cell.iconName = nil
            cell.disclosureType = .Switch
            cell.disclosureSwitch.on = switchItem.switchChecker()
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerTitle
    }
    
    
//    "settings-notifications-system-off" = "Notifications are currently turned off for Wikipedia. Go to your iOS Settings to turn on notifications";
//    "settings-notifications-system-turn-on" = "Turn on Notifications";
//    "settings-notifications-info" = "Be alerted to trending and top read articles on Wikipedia with our push notifications. All provided with respect to privacy and up to the minute data.";
//    "settings-notifications-learn-more" = "Learn more about notifications";
//    "settings-notifications-system-turn-on" = "Turn on Notifications";
//    "settings-notifications-trending" = "Trending current events";

}

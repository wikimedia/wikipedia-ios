import UIKit
import UserNotifications
import WMFModel

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
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] (note) in
            self?.updateSections()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
       super.viewWillAppear(animated)
       updateSections()
    }
    
    func sectionsForSystemSettingsAuthorized() -> [NotificationSettingsSection] {
        var updatedSections = [NotificationSettingsSection]()
        
        let infoItems: [NotificationSettingsItem] = [NotificationSettingsButtonItem(title: localizedStringForKeyFallingBackOnEnglish("settings-notifications-learn-more"), buttonAction: {
        })]
        
        let infoSection = NotificationSettingsSection(headerTitle: localizedStringForKeyFallingBackOnEnglish("settings-notifications-info"), items: infoItems)
        updatedSections.append(infoSection);
        
        let notificationSettingsItems: [NotificationSettingsItem] = [NotificationSettingsSwitchItem(title: localizedStringForKeyFallingBackOnEnglish("settings-notifications-trending"), switchChecker: { () -> Bool in
            return NSUserDefaults.wmf_userDefaults().wmf_inTheNewsNotificationsEnabled()
            }, switchAction: { (isOn) in
                if (!isOn) {
                    //This (and everything else that references UNUserNotificationCenter in this class) should be moved into WMFNotificationsController
                    if #available(iOS 10.0, *) {
                        UNUserNotificationCenter.currentNotificationCenter().removeAllPendingNotificationRequests()
                    }
                }
            NSUserDefaults.wmf_userDefaults().wmf_setInTheNewsNotificationsEnabled(isOn)
        })]
        let notificationSettingsSection = NotificationSettingsSection(headerTitle: localizedStringForKeyFallingBackOnEnglish("settings-notifications-push-notifications"), items: notificationSettingsItems)
        
        updatedSections.append(notificationSettingsSection)
        return updatedSections
    }
    
    func sectionsForSystemSettingsUnauthorized()  -> [NotificationSettingsSection] {
        let unauthorizedItems: [NotificationSettingsItem] = [NotificationSettingsButtonItem(title: localizedStringForKeyFallingBackOnEnglish("settings-notifications-system-turn-on"), buttonAction: {
            guard let URL = NSURL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            UIApplication.sharedApplication().openURL(URL)
        })]
        return [NotificationSettingsSection(headerTitle: localizedStringForKeyFallingBackOnEnglish("settings-notifications-info"), items: unauthorizedItems)]
    }
    
    func updateSections() {
        tableView.reloadData()
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.currentNotificationCenter().getNotificationSettingsWithCompletionHandler { (settings) in
                dispatch_async(dispatch_get_main_queue(), { 
                    switch settings.authorizationStatus {
                    case .Authorized:
                        fallthrough
                    case .NotDetermined:
                        self.sections = self.sectionsForSystemSettingsAuthorized()
                        break
                    case .Denied:
                        self.sections = self.sectionsForSystemSettingsUnauthorized()
                        break
                    }
                    self.tableView.reloadData()
                })
            }
        }
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
        cell.iconName = nil
        
        if let switchItem = item as? NotificationSettingsSwitchItem {
            cell.disclosureType = .Switch
            cell.disclosureSwitch.on = switchItem.switchChecker()
        } else {
            cell.disclosureType = .ViewController
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerTitle
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let item = sections[indexPath.section].items[indexPath.item] as? NotificationSettingsButtonItem else {
            return
        }
        
        item.buttonAction()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }
    
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return sections[indexPath.section].items[indexPath.item] as? NotificationSettingsSwitchItem == nil
    }
    
    
//    "settings-notifications-system-off" = "Notifications are currently turned off for Wikipedia. Go to your iOS Settings to turn on notifications";
//    "settings-notifications-system-turn-on" = "Turn on Notifications";
//    "settings-notifications-info" = "Be alerted to trending and top read articles on Wikipedia with our push notifications. All provided with respect to privacy and up to the minute data.";
//    "settings-notifications-learn-more" = "Learn more about notifications";
//    "settings-notifications-system-turn-on" = "Turn on Notifications";
//    "settings-notifications-trending" = "Trending current events";

}

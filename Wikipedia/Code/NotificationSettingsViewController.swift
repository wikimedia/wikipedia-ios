import UIKit
import UserNotifications
import WMF

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

@objc(WMFNotificationSettingsViewController)
class NotificationSettingsViewController: SubSettingsViewController {
    
    var sections = [NotificationSettingsSection]()
    var observationToken: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.notifications
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        observationToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (note) in
            self?.updateSections()
        }
    }
    
    deinit {
        if let token = observationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       updateSections()
    }
    
    func sectionsForSystemSettingsAuthorized() -> [NotificationSettingsSection] {
        var updatedSections = [NotificationSettingsSection]()
        
        let infoItems: [NotificationSettingsItem] = [NotificationSettingsButtonItem(title: WMFLocalizedString("settings-notifications-learn-more", value:"Learn more about notifications", comment:"A title for a button to learn more about notifications"), buttonAction: { [weak self] in
            let title = WMFLocalizedString("welcome-notifications-tell-me-more-title", value:"More about notifications", comment:"Title for detailed notification explanation")
            let message = "\(WMFLocalizedString("welcome-notifications-tell-me-more-storage", value:"Notification preferences are stored on device and not based on personal information or activity.", comment:"An explanation of how notifications are stored"))\n\n\(WMFLocalizedString("welcome-notifications-tell-me-more-creation", value:"Notifications are created and delivered on your device by the app, not from our (or third party) servers.", comment:"An explanation of how notifications are created"))"
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: CommonStrings.gotItButtonTitle, style: UIAlertAction.Style.default, handler: { (action) in
            }))
            self?.present(alertController, animated: true, completion: nil)
        })]
        
        let infoSection = NotificationSettingsSection(headerTitle: WMFLocalizedString("settings-notifications-info", value:"Be alerted to trending and top read articles on Wikipedia with our push notifications. All provided with respect to privacy and up to the minute data.", comment:"A short description of notifications shown in settings"), items: infoItems)
        updatedSections.append(infoSection)
        
        let notificationSettingsItems: [NotificationSettingsItem] = [NotificationSettingsSwitchItem(title: WMFLocalizedString("settings-notifications-trending", value:"Trending current events", comment:"Title for the setting for trending notifications"), switchChecker: { () -> Bool in
            return UserDefaults.standard.wmf_inTheNewsNotificationsEnabled()
            }, switchAction: { [weak self] (isOn) in
                //This (and everything else that references UNUserNotificationCenter in this class) should be moved into WMFNotificationsController
                if (isOn) {
                    // SINGLETONTODO
                    MWKDataStore.shared().notificationsController.requestAuthenticationIfNecessary(completionHandler: { [weak self] (granted, error) in
                        if let error = error as NSError? {
                            self?.wmf_showAlertWithError(error)
                        }
                    })
                } else {
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                }
                UserDefaults.standard.wmf_setInTheNewsNotificationsEnabled(isOn)
        })]
        let notificationSettingsSection = NotificationSettingsSection(headerTitle: WMFLocalizedString("settings-notifications-push-notifications", value:"Push notifications", comment:"A title for a list of Push notifications"), items: notificationSettingsItems)
        
        updatedSections.append(notificationSettingsSection)
        return updatedSections
    }
    
    func sectionsForSystemSettingsUnauthorized()  -> [NotificationSettingsSection] {
        let unauthorizedItems: [NotificationSettingsItem] = [NotificationSettingsButtonItem(title: WMFLocalizedString("settings-notifications-system-turn-on", value:"Turn on Notifications", comment:"Title for a button for turnining on notifications in the system settings"), buttonAction: {
            guard let URL = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        })]
        return [NotificationSettingsSection(headerTitle: WMFLocalizedString("settings-notifications-info", value:"Be alerted to trending and top read articles on Wikipedia with our push notifications. All provided with respect to privacy and up to the minute data.", comment:"A short description of notifications shown in settings"), items: unauthorizedItems)]
    }
    
    func updateSections() {
        tableView.reloadData()
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            DispatchQueue.main.async(execute: {
                switch settings.authorizationStatus {
                case .authorized:
                    fallthrough
                case .notDetermined:
                    self.sections = self.sectionsForSystemSettingsAuthorized()
                    break
                case .denied:
                    self.sections = self.sectionsForSystemSettingsUnauthorized()
                    break
                default:
                    break
                }
                self.tableView.reloadData()
            })
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        let item = sections[indexPath.section].items[indexPath.item]
        cell.title = item.title
        cell.iconName = nil
        
        if let tc = cell as Themeable? {
            tc.apply(theme: theme)
        }
        
        if let switchItem = item as? NotificationSettingsSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.isOn = switchItem.switchChecker()
            cell.disclosureSwitch.addTarget(self, action: #selector(self.handleSwitchValueChange(_:)), for: .valueChanged)
        } else {
            cell.disclosureType = .viewController
        }
        
        
        return cell
    }
    
    @objc func handleSwitchValueChange(_ sender: UISwitch) {
        // FIXME: hardcoded item below
        let item = sections[1].items[0]
        if let switchItem = item as? NotificationSettingsSwitchItem {
            switchItem.switchAction(sender.isOn)
        }
    }

    @objc func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = WMFTableHeaderFooterLabelView.wmf_viewFromClassNib() else {
            return nil
        }
        if let th = header as Themeable? {
            th.apply(theme: theme)
        }
        header.text = sections[section].headerTitle
        return header;
    }
    
    @objc func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let header = WMFTableHeaderFooterLabelView.wmf_viewFromClassNib() else {
            return 0
        }
        header.text = sections[section].headerTitle
        return header.height(withExpectedWidth: self.view.frame.width - tableView.separatorInset.left - tableView.separatorInset.right)
    }
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = sections[indexPath.section].items[indexPath.item] as? NotificationSettingsButtonItem else {
            return
        }
        
        item.buttonAction()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    @objc func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].items[indexPath.item] as? NotificationSettingsSwitchItem == nil
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.reloadData()
    }
}

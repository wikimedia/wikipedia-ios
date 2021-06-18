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
    @objc var pushNotificationsController: PushNotificationsController?
    
    private var pushFullyEnabled: Bool = false {
        didSet {
            updateSections()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.notifications
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        observationToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (note) in
            self?.pushNotificationsController?.checkNotificationsFullyEnabled(completion: { fullyEnabled in
                self?.pushFullyEnabled = fullyEnabled
            })
        }
    }
    
    deinit {
        if let token = observationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        pushNotificationsController?.checkNotificationsFullyEnabled(completion: { [weak self] fullyEnabled in
            self?.pushFullyEnabled = fullyEnabled
        })
    }
    
    func sectionsForSystemSettingsAuthorized() -> [NotificationSettingsSection] {
        var updatedSections = [NotificationSettingsSection]()
        
        let notificationSettingsItems: [NotificationSettingsItem] = [NotificationSettingsSwitchItem(title: WMFLocalizedString("settings-notifications-enable-push-notifications", value:"Enable push notifications", comment:"Title for enabling push notifications"), switchChecker: { () -> Bool in
            return self.pushFullyEnabled
            }, switchAction: { [weak self] (isOn) in
                //This (and everything else that references UNUserNotificationCenter in this class) should be moved into WMFNotificationsController
                if (isOn) {
                    self?.pushNotificationsController?.fullyEnableNotifications(completion: { [weak self] success, error in
                        if let error = error {
                            self?.wmf_showAlertWithError(error as NSError)
                            return
                        }
                        
                        if success {
                            self?.pushFullyEnabled = true
                        }
                    })
                } else {
                    self?.pushNotificationsController?.fullyDisableNotifications(completion: { [weak self] success, error in
                        if let error = error {
                            self?.wmf_showAlertWithError(error as NSError)
                            return
                        }
                        
                        if success {
                            self?.pushFullyEnabled = false
                        }
                    })
                }
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
        let item = sections[0].items[0]
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

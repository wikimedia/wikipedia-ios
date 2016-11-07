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

class NotificationSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WMFAnalyticsContextProviding, WMFAnalyticsContentTypeProviding {

    @IBOutlet weak var tableView: UITableView!
    
    
    var sections = [NotificationSettingsSection]()
    var observationToken: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.registerNib(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.delegate = self
        tableView.dataSource = self
        observationToken = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] (note) in
            self?.updateSections()
        }
    }
    
    deinit {
        if let token = observationToken {
            NSNotificationCenter.defaultCenter().removeObserver(token)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
       super.viewWillAppear(animated)
       updateSections()
    }
    
    func analyticsContext() -> String {
        return "notification"
    }
    
    func analyticsContentType() -> String {
        return "current events"
    }
    
    func sectionsForSystemSettingsAuthorized() -> [NotificationSettingsSection] {
        var updatedSections = [NotificationSettingsSection]()
        
        let infoItems: [NotificationSettingsItem] = [NotificationSettingsButtonItem(title: localizedStringForKeyFallingBackOnEnglish("settings-notifications-learn-more"), buttonAction: { [weak self] in
            let title = localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-title")
            let message = "\(localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-storage"))\n\n\(localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-creation"))"
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: localizedStringForKeyFallingBackOnEnglish("button-ok"), style: UIAlertActionStyle.Default, handler: { (action) in
            }))
            self?.presentViewController(alertController, animated: true, completion: nil)
        })]
        
        let infoSection = NotificationSettingsSection(headerTitle: localizedStringForKeyFallingBackOnEnglish("settings-notifications-info"), items: infoItems)
        updatedSections.append(infoSection)
        
        let notificationSettingsItems: [NotificationSettingsItem] = [NotificationSettingsSwitchItem(title: localizedStringForKeyFallingBackOnEnglish("settings-notifications-trending"), switchChecker: { () -> Bool in
            return NSUserDefaults.wmf_userDefaults().wmf_inTheNewsNotificationsEnabled()
            }, switchAction: { (isOn) in
                //This (and everything else that references UNUserNotificationCenter in this class) should be moved into WMFNotificationsController
                if #available(iOS 10.0, *) {
                    if (isOn) {
                        WMFNotificationsController.sharedNotificationsController().requestAuthenticationIfNecessaryWithCompletionHandler({ (granted, error) in
                            if let error = error {
                                self.wmf_showAlertWithError(error)
                            }
                        })
                    } else {
                        UNUserNotificationCenter.currentNotificationCenter().removeAllPendingNotificationRequests()
                    }
                }
                
                if isOn {
                    PiwikTracker.sharedInstance()?.wmf_logActionEnableInContext(self, contentType: self)
                }else{
                    PiwikTracker.sharedInstance()?.wmf_logActionDisableInContext(self, contentType: self)
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
            cell.disclosureSwitch.addTarget(self, action: #selector(self.handleSwitchValueChange(_:)), forControlEvents: .ValueChanged)
        } else {
            cell.disclosureType = .ViewController
        }
        
        
        return cell
    }
    
    func handleSwitchValueChange(sender: UISwitch) {
        // FIXME: hardcoded item below
        let item = sections[1].items[0]
        if let switchItem = item as? NotificationSettingsSwitchItem {
            switchItem.switchAction(sender.on)
        }
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        header.text = sections[section].headerTitle
        return header;
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        header.text = sections[section].headerTitle
        return header.heightWithExpectedWidth(self.view.frame.width)
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
}

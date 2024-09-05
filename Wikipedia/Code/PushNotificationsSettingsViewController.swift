import UIKit
import WMF
import UserNotifications

fileprivate protocol PushNotificationsSettingsItem {
    var title: String { get }
    var iconName: String? { get }
}

@objc(WMFPushNotificationsSettingsViewController)
final class PushNotificationsSettingsViewController: SubSettingsViewController {

    // MARK: - Nested Types

    fileprivate struct PushNotificationsSettingsSection {
        let headerText: String
        let items: [PushNotificationsSettingsItem]
    }

    fileprivate struct PushNotificationsSettingsActionItem: PushNotificationsSettingsItem {
        let title: String
        let iconName: String? = nil
        let action: () -> Void
    }

    fileprivate struct PushNotificationsSettingsSwitchItem: PushNotificationsSettingsItem {
        let title: String
        let iconName: String? = nil
        let tag: Int
        let valueChecker: () -> Bool
        let action: (Bool) -> Void
    }

    // MARK: - Properties

    private let authenticationManager: WMFAuthenticationManager
    private let notificationsController: WMFNotificationsController

    private var activeApplicationObservationToken: NSObjectProtocol?
    private var sections: [PushNotificationsSettingsSection] = []

    fileprivate var deviceTokenRetryTask: RetryBlockTask?

    fileprivate let headerText = WMFLocalizedString("settings-notifications-header", value: "Be alerted to activity related to your account, such as messages from fellow contributors, alerts, and notices. All provided with respect to privacy and up to the minute data.", comment: "Text informing user of benefits of enabling push notifications.") + "\n"

    fileprivate let echoAlertFailureTitle = WMFLocalizedString("settings-notifications-echo-failure-title", value: "Unable to Check for Echo Notification subscriptions", comment: "Alert title text informing user of failure when subscribing to Echo Notifications.")
    fileprivate let echoAlertFailureMessage = WMFLocalizedString("settings-notifications-echo-failure-message", value: "An error occurred while checking for notification subscriptions related to your account.", comment: "Alert message text informing user of failure when subscribing to Echo Notifications.")
    fileprivate let echoAlertFailureTryAgainActionTitle = CommonStrings.tryAgain

    // MARK: - Lifecycle

    @objc init(authenticationManager: WMFAuthenticationManager, notificationsController: WMFNotificationsController) {
        self.authenticationManager = authenticationManager
        self.notificationsController = notificationsController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.pushNotifications

        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44

        activeApplicationObservationToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.didReceiveWillEnterForegroundNotification()
        })
    }

    deinit {
        deviceTokenRetryTask = nil
        if let token = activeApplicationObservationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSections()
    }

    // MARK: - Application Foreground Notification

    private func didReceiveWillEnterForegroundNotification() {
        guard authenticationManager.authStateIsPermanent else {
            self.navigationController?.popViewController(animated: true)
            return
        }

        updateSections()
    }

    // MARK: - UITableView Data

    private func updateSections() {
        notificationsController.notificationPermissionsStatus(completionHandler: { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }

                switch status {
                case .authorized, .provisional, .ephemeral:
                    // The user has authorized system push alert permissions.
                    //  - Switch is only on if user is subscribed to echo notifications and authorized for device push alerts
                    let pushSwitchItem = PushNotificationsSettingsSwitchItem(title: CommonStrings.pushNotifications, tag: 0, valueChecker: {
                        return UserDefaults.standard.wmf_isSubscribedToEchoNotifications
                    }, action: { [weak self] isOn in
                        if isOn {
                            self?.requestPushPermissions()
                        } else {
                            self?.unsubscribeFromEchoNotifications()
                        }
                    })

                    let pushStatusSection = PushNotificationsSettingsSection(headerText: self.headerText, items: [pushSwitchItem])
                    // If `UserDefaults.standard.wmf_isSubscribedToEchoNotifications`, also show notification type section
                    self.sections = [pushStatusSection]
                case .notDetermined:
                    // The user hasn't yet triggered a request for push alert permissions.
                    //  - Switch is always off. The user toggling the switch will begin the push alert, device token, and echo subscription flow.
                    let pushSwitchItem = PushNotificationsSettingsSwitchItem(title: CommonStrings.pushNotifications, tag: 0, valueChecker: {
                        return false
                    }, action: { [weak self] isOn in
                        if isOn {
                            self?.requestPushPermissions()
                        }
                    })

                    let pushStatusSection = PushNotificationsSettingsSection(headerText: self.headerText, items: [pushSwitchItem])
                    self.sections = [pushStatusSection]
                default:
                    // User has been asked and has denied permissions. This can only be re-enabled in system settings.
                    // - Only show an item redirecting the user to the system settings.
                    let pushSystemSettingsItem = PushNotificationsSettingsActionItem(title: CommonStrings.pushNotifications, action: {
                        UIApplication.shared.wmf_openAppSpecificSystemSettings()
                    })

                    let pushStatusSection = PushNotificationsSettingsSection(headerText: self.headerText, items: [pushSystemSettingsItem])
                    self.sections = [pushStatusSection]
                }

                self.tableView.reloadData()
            }
        })
    }

    // MARK: - UITableView

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
        cell.iconName = item.iconName

        if let themeableCell = cell as Themeable? {
            themeableCell.apply(theme: theme)
        }

        if let switchItem = item as? PushNotificationsSettingsSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.tag = switchItem.tag
            cell.disclosureSwitch.isOn = switchItem.valueChecker()
            cell.disclosureSwitch.addTarget(self, action: #selector(userDidTapSwitch(_:)), for: .valueChanged)
        } else if item is PushNotificationsSettingsActionItem {
            cell.disclosureType = .externalLink
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = WMFTableHeaderFooterLabelView.wmf_viewFromClassNib() else {
            return nil
        }

        if let themeableHeader = header as Themeable? {
            themeableHeader.apply(theme: theme)
        }

        header.text = sections[section].headerText
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = sections[indexPath.section].items[indexPath.item] as? PushNotificationsSettingsActionItem else {
            return
        }

        item.action()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].items[indexPath.item] as? PushNotificationsSettingsSwitchItem == nil
    }

    // MARK: - UI Actions

    @objc func userDidTapSwitch(_ sender: UISwitch) {
        let items = sections.flatMap { section in section.items }.compactMap { item in item as? PushNotificationsSettingsSwitchItem }
        if let tappedSwitchItem = items.first(where: { item in item.tag == sender.tag }) {
            tappedSwitchItem.action(sender.isOn)
        }
    }

    // MARK: - Themeable

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

// MARK: - System push alert/badge permissions and echo subscription/unsubscription

extension PushNotificationsSettingsViewController {

    fileprivate func requestPushPermissions() {
        deviceTokenRetryTask = RetryBlockTask { [weak self] in
            return self?.notificationsController.remoteRegistrationDeviceToken != nil
        }

        notificationsController.requestPermissionsIfNecessary { (authorized, error) in
            DispatchQueue.main.async {
                if authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                    if self.notificationsController.remoteRegistrationDeviceToken == nil {
                        // If we still don't have a device token, disable table interaction and retry checking for one
                        self.updatePrimaryPushSwitch(userInteractionEnabled: false)
                        self.deviceTokenRetryTask?.start { [weak self] success in
                            guard let self = self else { return }
                            DispatchQueue.main.async {
                                self.updatePrimaryPushSwitch(userInteractionEnabled: true)
                            }
                            if success {
                                DispatchQueue.main.async {
                                    self.subscribeToEchoNotifications()
                                }
                            } else {
                                // If we're still awaiting a device token, show an alert and offer the user the opportunity to manually retry fetching one
                                DispatchQueue.main.async {
                                    self.showDeviceTokenRetryAlert()
                                }
                            }
                        }
                    } else {
                        // User is authorized for on device push alerts and is now awaiting subscription to Echo Notifications
                        self.subscribeToEchoNotifications()
                    }
                } else {
                    // User isn't authorized, just update sections to a failure state
                    self.updateSections()
                }
            }
        }
    }

    fileprivate func showDeviceTokenRetryAlert() {
        let retryAction = UIAlertAction(title: echoAlertFailureTryAgainActionTitle, style: .default, handler: { _ in self.requestPushPermissions() })
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in self.updateSections() })
        self.wmf_showAlert(title: echoAlertFailureTitle, message: echoAlertFailureMessage, actions: [retryAction, cancelAction], completion: {
            // Silently trigger a remote registration request to fetch a device token
            UIApplication.shared.registerForRemoteNotifications()
        })
    }

    fileprivate func subscribeToEchoNotifications() {
        updatePrimaryPushSwitch(userInteractionEnabled: false)
        notificationsController.subscribeToEchoNotifications(completionHandler: { error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updatePrimaryPushSwitch(userInteractionEnabled: true)
                guard error == nil else {
                    let retryAction = UIAlertAction(title: self.echoAlertFailureTryAgainActionTitle, style: .default, handler: { _ in self.subscribeToEchoNotifications() })
                    let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in self.updateSections() })
                    self.wmf_showAlert(title: self.echoAlertFailureTitle, message: self.echoAlertFailureMessage, actions: [retryAction, cancelAction])
                    return
                }

                self.updateSections()
            }
        })
    }

    fileprivate func unsubscribeFromEchoNotifications() {
        updatePrimaryPushSwitch(userInteractionEnabled: false)
        notificationsController.unsubscribeFromEchoNotifications(completionHandler: { error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updatePrimaryPushSwitch(userInteractionEnabled: true)
                guard error == nil else {
                    let retryAction = UIAlertAction(title: self.echoAlertFailureTryAgainActionTitle, style: .default, handler: { _ in self.unsubscribeFromEchoNotifications() })
                    let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in self.updateSections() })
                    self.wmf_showAlert(title: self.echoAlertFailureTitle, message: self.echoAlertFailureMessage, actions: [retryAction, cancelAction])
                    return
                }

                self.updateSections()
            }
        })
    }

    fileprivate func updatePrimaryPushSwitch(userInteractionEnabled: Bool) {
        guard let primaryPushSwitchCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WMFSettingsTableViewCell else {
            return
        }

        primaryPushSwitchCell.disclosureSwitch.isUserInteractionEnabled = userInteractionEnabled
    }

}

import UIKit

protocol AppearanceSettingsItem {
    var title: String? { get }
}

struct AppearanceSettingsSwitchItem: AppearanceSettingsItem {
    let title: String?
}

struct AppearanceSettingsCheckmarkItem: AppearanceSettingsItem {
    let title: String?
    let theme: Theme
    let checkmarkAction: () -> Void
}

struct AppearanceSettingsSection {
    let headerTitle: String
    let footerText: String?
    let items: [AppearanceSettingsItem]
}

@objc(WMFAppearanceSettingsViewController)
open class AppearanceSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections = [AppearanceSettingsSection]()
    
    fileprivate var theme = Theme.standard
    
    static var disclosureText: String {
        let currentAppTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        return currentAppTheme.displayName
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        title = WMFLocalizedString("appearance-settings-title", value: "Reading themes", comment: "Title of the Appearance view in Settings.")
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        sections = sectionsForAppearanceSettings()
        apply(theme: self.theme)
    }
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        
        let readingThemesSection =
            AppearanceSettingsSection(headerTitle: WMFLocalizedString("appearance-settings-reading-themes", value: "Reading themes", comment: "Title of the the Reading themes section in Appearance settings"), footerText: nil, items: [AppearanceSettingsCheckmarkItem(title: Theme.light.displayName, theme: Theme.light, checkmarkAction: {self.userDidSelect(theme: Theme.light)}), AppearanceSettingsCheckmarkItem(title: Theme.sepia.displayName, theme: Theme.sepia, checkmarkAction: {self.userDidSelect(theme: Theme.sepia)}), AppearanceSettingsCheckmarkItem(title: Theme.dark.displayName, theme: Theme.dark, checkmarkAction: {self.userDidSelect(theme: Theme.dark)})])
        
        let themeOptionsSection = AppearanceSettingsSection(headerTitle: WMFLocalizedString("appearance-settings-theme-options", value: "Theme options", comment: "Title of the Theme options section in Appearance settings"), footerText: nil, items: [AppearanceSettingsSwitchItem(title: CommonStrings.dimImagesTitle)])
        
        return [readingThemesSection, themeOptionsSection]
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        let item = sections[indexPath.section].items[indexPath.item]
        cell.title = item.title
        cell.iconName = nil
        
        if let tc = cell as Themeable? {
            tc.apply(theme: theme)
        }
        
        if item is AppearanceSettingsSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.isEnabled = false
            cell.disclosureSwitch.isOn = UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled
            
            let currentAppTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
            switch currentAppTheme {
            case  Theme.darkDimmed:
                fallthrough
            case Theme.dark:
                cell.disclosureSwitch.isEnabled = true
                cell.disclosureSwitch.addTarget(self, action: #selector(self.handleImageDimmingSwitchValueChange(_:)), for: .valueChanged)
            default:
                break
            }
            
            cell.iconName = "settings-image-dimming"
            cell.iconBackgroundColor = self.theme.colors.secondaryText
            cell.iconColor = self.theme.colors.paperBackground
        } else {
            cell.disclosureType = .none
        }
        
        return cell
    }
    
    func userDidSelect(theme: Theme) {
        let userInfo = ["theme": theme]
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCheckmarkItem else {
            return
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        item.checkmarkAction()
    }
    
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard sections[indexPath.section].items[indexPath.item] is AppearanceSettingsCheckmarkItem else {
            return nil
        }
        return indexPath
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currentAppTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        
        if let checkmarkItem = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCheckmarkItem {
            
            switch currentAppTheme {
            case Theme.darkDimmed where checkmarkItem.title == "Dark":
                fallthrough
            case checkmarkItem.theme:
                cell.accessoryType = .checkmark
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            default:
                break
            }
    
        }
    }
    
    func applyImageDimmingChange(isOn: NSNumber) {
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled = isOn.boolValue
        userDidSelect(theme: currentTheme.withDimmingEnabled(isOn.boolValue))
    }
    
    func handleImageDimmingSwitchValueChange(_ sender: UISwitch) {
        let selector = #selector(applyImageDimmingChange)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(selector, with: NSNumber(value: sender.isOn), afterDelay: CATransaction.animationDuration())
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerTitle
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }
    
}

extension AppearanceSettingsViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.reloadData()
    }
}

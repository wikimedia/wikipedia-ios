import UIKit

@objc public protocol WMFAppearanceSettingsViewControllerDelegate {
    func themeCangedInController(_ controller: AppearanceSettingsViewController, theme: Theme)
}

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

struct AppearanceSettingsCustomViewItem: AppearanceSettingsItem {
    let title: String?
    let viewController: UIViewController
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
    
    open weak var delegate: WMFAppearanceSettingsViewControllerDelegate?
    
    
    static var disclosureText: String {
        var text = WMFLocalizedString("default-theme-display-name", value: "Default", comment: "Default theme name presented to the user")
        let currentAppTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        
        if currentAppTheme == Theme.sepia {
            text = WMFLocalizedString("sepia-theme-display-name", value: "Sepia", comment: "Sepia theme name presented to the user")
        } else if currentAppTheme == Theme.dark || currentAppTheme == Theme.darkDimmed {
            text = WMFLocalizedString("dark-theme-display-name", value: "Dark", comment: "Dark theme name presented to the user")
        }
        
        return text
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        sections = sectionsForAppearanceSettings()
        apply(theme: self.theme)
    }
    
    func defaultThemeDisplayName() -> String {
        return WMFLocalizedString("default-theme-display-name", value: "Default", comment: "Default theme name presented to the user")
    }
    
    func sepiaThemeDisplayName() -> String {
        return WMFLocalizedString("sepia-theme-display-name", value: "Sepia", comment: "Sepia theme name presented to the user")
    }
    
    func darkThemeDisplayName() -> String {
        return WMFLocalizedString("dark-theme-display-name", value: "Dark", comment: "Dark theme name presented to the user")
    }
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        
        let readingThemesSection =
            AppearanceSettingsSection(headerTitle: WMFLocalizedString("reading-themes", value: "Reading themes", comment: "Title of the the Reading themes section in Appearance settings"), footerText: nil, items: [AppearanceSettingsCheckmarkItem(title: defaultThemeDisplayName(), theme: Theme.light, checkmarkAction: {self.userDidSelect(theme: Theme.light)}), AppearanceSettingsCheckmarkItem(title: sepiaThemeDisplayName(), theme: Theme.sepia, checkmarkAction: {self.userDidSelect(theme: Theme.sepia)}), AppearanceSettingsCheckmarkItem(title: darkThemeDisplayName(), theme: Theme.dark, checkmarkAction: {self.userDidSelect(theme: Theme.dark)})])
        
        let themeOptionsSection = AppearanceSettingsSection(headerTitle: WMFLocalizedString("theme-options", value: "Theme options", comment: "Title of the Theme options section in Appearance settings"), footerText: WMFLocalizedString("theme-options-footer", value: "Automatically apply the ‘Dark’ reading theme between 8pm and 8am", comment: "Footer of the Theme options section in Appearance settings"), items: [AppearanceSettingsSwitchItem(title: WMFLocalizedString("image-dimming", value: "Image dimming", comment: "Title of the image dimming switch in Appearance settings"))])
        
        let textSizingSection = AppearanceSettingsSection(headerTitle: WMFLocalizedString("adjust-text-sizing", value: "Adjust text sizing", comment: "Header of the Text sizing section in Appearance settings"), footerText: WMFLocalizedString("adjust-text-sizing-footer", value: "Drag the slider above", comment: "Footer of the Adjust text sizing section in Appearance settings"), items: [AppearanceSettingsCustomViewItem(title: nil, viewController: FontSizeSliderViewController.init(nibName: "FontSizeSliderViewController", bundle: nil))])
        
        return [readingThemesSection, themeOptionsSection, textSizingSection]
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
        
        if let customViewItem = item as? AppearanceSettingsCustomViewItem, let vc = customViewItem.viewController as? FontSizeSliderViewController, let view = vc.viewIfLoaded {
            vc.apply(theme: self.theme)
            var frame = view.frame
            frame.size.width = cell.frame.width
            view.frame = frame
            cell.contentView.addSubview(view)
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
        
        if let delegate = self.delegate {
            delegate.themeCangedInController(self, theme: theme)
        }
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
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCustomViewItem else {
            return tableView.rowHeight
        }
        return item.viewController.view.frame.height
    }
    
    func handleImageDimmingSwitchValueChange(_ sender: UISwitch) {
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled = sender.isOn
        userDidSelect(theme: currentTheme.withDimmingEnabled(sender.isOn))
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        if let th = header as Themeable? {
            th.apply(theme: theme)
        }
        header?.text = sections[section].headerTitle
        return header
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        if let th = footer as Themeable? {
            th.apply(theme: theme)
        }
        footer?.setShortTextAsProse(sections[section].footerText)
        return footer
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footerText = sections[section].footerText else {
            return 0
        }
        
        let footer = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        footer?.text = footerText
        return footer!.height(withExpectedWidth: self.view.frame.width)
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        header?.text = sections[section].headerTitle
        return header!.height(withExpectedWidth: self.view.frame.width)
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

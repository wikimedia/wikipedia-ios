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
        var text = "Default"
        
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        if currentTheme == Theme.sepia {
            text = "Sepia"
        } else if currentTheme == Theme.dark {
            text = "Dark"
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
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        
        let readingThemesSection =
            AppearanceSettingsSection(headerTitle: "Reading themes", footerText: nil, items: [AppearanceSettingsCheckmarkItem(title: "Default", theme: Theme.light, checkmarkAction: {self.userDidSelect(theme: Theme.light)}), AppearanceSettingsCheckmarkItem(title: "Sepia", theme: Theme.sepia, checkmarkAction: {self.userDidSelect(theme: Theme.sepia)}), AppearanceSettingsCheckmarkItem(title: "Dark", theme: Theme.dark, checkmarkAction: {self.userDidSelect(theme: Theme.dark)})])
        
        let themeOptionsSection = AppearanceSettingsSection(headerTitle: "Theme options", footerText: "Automatically apply the ‘Dark’ reading theme between 8pm and 8am", items: [AppearanceSettingsSwitchItem(title: "Image dimming"), AppearanceSettingsSwitchItem(title: "Auto-night mode")])
        
        let textSizingSection = AppearanceSettingsSection(headerTitle: "Adjust text sizing", footerText: "Drag the slider above", items: [AppearanceSettingsCustomViewItem(title: nil, viewController: FontSizeSliderViewController.init(nibName: "FontSizeSliderViewController", bundle: nil))])
        
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
        
        if let switchItem = item as? AppearanceSettingsSwitchItem {
            cell.disclosureType = .switch
            // disable until implemented
            cell.disclosureSwitch.isEnabled = false
            if switchItem.title == "Image dimming" {
                //TODO: get a real icon
                cell.iconName = "settings-notifications"
                cell.disclosureSwitch.addTarget(self, action: #selector(self.handleImageDimmingSwitchValueChange(_:)), for: .valueChanged)
            } else {
                //TODO: get a real icon
                cell.iconName = "settings-notifications"
                cell.disclosureSwitch.addTarget(self, action: #selector(self.handleAutoNightModeSwitchValueChange(_:)), for: .valueChanged)
            }
        } else {
            cell.disclosureType = .none
        }
        
        return cell
    }
    
    func userDidSelect(theme: Theme) {
        let userInfo = ["theme": theme]
        //TODO: move WMFUserDidSelectThemeNotification
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
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let checkmarkItem = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCheckmarkItem, checkmarkItem.theme == UserDefaults.wmf_userDefaults().wmf_appTheme {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCustomViewItem else {
            return tableView.rowHeight
        }
        return item.viewController.view.frame.height
    }
    
    func handleImageDimmingSwitchValueChange(_ sender: UISwitch) {
    }
    
    func handleAutoNightModeSwitchValueChange(_ sender: UISwitch) {
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

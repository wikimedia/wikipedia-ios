import UIKit

protocol AppearanceSettingsItem {
    var title: String? { get }
    var subtitle: String? { get }
}

struct AppearanceSettingsDimSwitchItem: AppearanceSettingsItem {
    let title: String?
    let subtitle: String?
}

struct AppearanceSettingsAutomaticTableOpenSwitchItem: AppearanceSettingsItem {
    let title: String?
    let subtitle: String?
}

struct AppearanceSettingsCheckmarkItem: AppearanceSettingsItem {
    let title: String?
    let subtitle: String?
    let theme: String
    let checkmarkAction: () -> Void
}

struct AppearanceSettingsSection {
    let headerTitle: String?
    let footerText: String?
    let items: [AppearanceSettingsItem]
}

struct AppearanceSettingsCustomViewItem: AppearanceSettingsItem {
    let title: String?
    let subtitle: String?
    let viewController: UIViewController
}

struct AppearanceSettingsSpacerViewItem: AppearanceSettingsItem {
    var title: String?
    let subtitle: String?
    let spacing: CGFloat
}

@objc(WMFAppearanceSettingsViewController)
final class AppearanceSettingsViewController: SubSettingsViewController {
    static let customViewCellReuseIdentifier = "org.wikimedia.custom"

    var sections = [AppearanceSettingsSection]()

    @objc static var disclosureText: String {
        return UserDefaults.standard.themeDisplayName
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        title = CommonStrings.readingPreferences
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: AppearanceSettingsViewController.customViewCellReuseIdentifier)
        sections = sectionsForAppearanceSettings()
    }
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        
        func checkmarkItem(for theme: Theme) -> (AppearanceSettingsCheckmarkItem) {
            return AppearanceSettingsCheckmarkItem(title: theme.displayName, subtitle: nil, theme: theme.name) { [weak self] in
                self?.userDidSelect(theme: theme.name)
            }
        }

        let subtitle =   WMFLocalizedString("theme-default-explanation", value:"Matches system theme", comment: "Explains that the default theme matches the iOS system theme setting")
        
        let defaultThemeItem = AppearanceSettingsCheckmarkItem(title: CommonStrings.defaultThemeDisplayName, subtitle: subtitle, theme: Theme.defaultThemeName, checkmarkAction: { [weak self] in
            self?.userDidSelect(theme: Theme.defaultThemeName)
        })
        
        let items = [defaultThemeItem, checkmarkItem(for: Theme.light), checkmarkItem(for: Theme.sepia), checkmarkItem(for: Theme.dark), checkmarkItem(for: Theme.black)]
        
        let readingThemesSection =
            AppearanceSettingsSection(headerTitle: WMFLocalizedString("appearance-settings-reading-themes", value: "Reading themes", comment: "Title of the Reading themes section in Appearance settings"), footerText: nil, items: items)
        
        let themeOptionsSection = AppearanceSettingsSection(headerTitle: WMFLocalizedString("appearance-settings-theme-options", value: "Theme options", comment: "Title of the Theme options section in Appearance settings"), footerText: WMFLocalizedString("appearance-settings-image-dimming-footer", value: "Decrease the opacity of images on the dark and black themes", comment: "Footer of the Theme options section in Appearance settings, explaining image dimming"), items: [AppearanceSettingsCustomViewItem(title: nil, subtitle: nil, viewController: ImageDimmingExampleViewController(nibName: "ImageDimmingExampleViewController", bundle: nil)), AppearanceSettingsSpacerViewItem(title: nil, subtitle: nil, spacing: 15.0), AppearanceSettingsDimSwitchItem(title: CommonStrings.dimImagesTitle, subtitle: nil)])
        
        let tableAutomaticOpenSection = AppearanceSettingsSection(headerTitle: WMFLocalizedString("appearance-settings-set-automatic-table-opening", value: "Table Settings", comment: "Tables in article will be opened automatically"), footerText: WMFLocalizedString("appearance-settings-expand-tables-footer", value: "Set all tables in all articles to be open by default, including Quick facts, References, Notes and External links.", comment: "Footer of the expand tables section in Appearance settings, explaining the expand tables setting"), items: [AppearanceSettingsAutomaticTableOpenSwitchItem(title: WMFLocalizedString("appearance-settings-expand-tables", value: "Expand tables", comment: "Title for the setting that expands tables in an article by default"), subtitle: nil)])
        
        let textSizingSection = AppearanceSettingsSection(headerTitle: WMFLocalizedString("appearance-settings-adjust-text-sizing", value: "Adjust article text sizing", comment: "Header of the Text sizing section in Appearance settings"), footerText: nil, items: [AppearanceSettingsCustomViewItem(title: nil, subtitle: nil, viewController: TextSizeChangeExampleViewController(nibName: "TextSizeChangeExampleViewController", bundle: nil)), AppearanceSettingsSpacerViewItem(title: nil, subtitle: nil, spacing: 15.0), AppearanceSettingsCustomViewItem(title: nil, subtitle: nil, viewController: FontSizeSliderViewController(nibName: "FontSizeSliderViewController", bundle: nil))])
        
        return [readingThemesSection, themeOptionsSection, tableAutomaticOpenSection, textSizingSection]
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.item]
        
        if let customViewItem = item as? AppearanceSettingsCustomViewItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: AppearanceSettingsViewController.customViewCellReuseIdentifier, for: indexPath)
            let vc = customViewItem.viewController

            if let view = vc.view {
                addChild(vc)
                view.frame = cell.contentView.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(view)
                vc.didMove(toParent: self)
            }
            
            if let themeable = vc as? Themeable {
                themeable.apply(theme: self.theme)
                cell.backgroundColor = vc.view.backgroundColor
            }
            
            if let dimming = vc as? ImageDimmingExampleViewController {
                // themeTODO: define a semantic color for this instead of checking isDark
                dimming.view.backgroundColor = self.theme.isDark ? self.theme.colors.paperBackground : .darkBase20
                dimming.isImageDimmed = UserDefaults.standard.wmf_isImageDimmingEnabled
            }
            
            cell.selectionStyle = .none
            return cell
        }
        
        if item is AppearanceSettingsSpacerViewItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: AppearanceSettingsViewController.customViewCellReuseIdentifier, for: indexPath)
            cell.backgroundColor = tableView.backgroundColor
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.title = item.title
        cell.subtitle = item.subtitle
        cell.iconName = nil
        
        if let tc = cell as Themeable? {
            tc.apply(theme: theme)
        }

        if item is AppearanceSettingsDimSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.isOn = UserDefaults.standard.wmf_isImageDimmingEnabled
            cell.disclosureSwitch.addTarget(self, action: #selector(self.handleImageDimmingSwitchValueChange(_:)), for: .valueChanged)
            cell.iconName = "settings-image-dimming"
            cell.iconBackgroundColor = .base50
            cell.iconColor = .white
            cell.selectionStyle = .none
        }
        else if item is AppearanceSettingsAutomaticTableOpenSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.isEnabled = true
            cell.disclosureSwitch.isOn = UserDefaults.standard.wmf_isAutomaticTableOpeningEnabled
            cell.disclosureSwitch.addTarget(self, action: #selector(self.handleAutomaticTableOpenSwitchValueChange(_:)), for: .valueChanged)
            cell.iconName = "settings-tables-expand"
            cell.iconBackgroundColor = UIColor.wmf_colorWithHex(0x5C97BF)
            cell.iconColor = .white
            cell.selectionStyle = .none
        } else {
            cell.disclosureType = .none
        }

        if let iconBackgroundColor = theme.colors.iconBackground, let iconColor = theme.colors.icon {
            cell.iconBackgroundColor = iconColor
            cell.iconColor = iconBackgroundColor
        }

        return cell
    }
    
    // keep @objc on UITableViewDelegate methods otherwise they aren't called on release builds
    @objc public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.item]
        guard let customViewItem = item as? AppearanceSettingsCustomViewItem else {
            return
        }
        let vc = customViewItem.viewController
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        if let cell = cell as? WMFSettingsTableViewCell {
            cell.disclosureSwitch.removeTarget(nil, action: nil, for: .valueChanged)
        }
    }
    
    func userDidSelect(theme: String, isImageDimmingEnabled: Bool? = nil) {
        var userInfo: [String: Any] = [ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeNameKey: theme]
        if let isImageDimmingEnabled = isImageDimmingEnabled {
            userInfo[ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationIsImageDimmingEnabledKey] = NSNumber(booleanLiteral: isImageDimmingEnabled)
        }
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
    }
    
    @objc public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let customViewItem = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCustomViewItem {
            return customViewItem.viewController.view.frame.height
        } else if let spacerViewItem = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsSpacerViewItem {
            return spacerViewItem.spacing
        }
        return tableView.rowHeight
    }
    
    @objc public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCheckmarkItem else {
            return
        }
        item.checkmarkAction()
        tableView.reloadData()
    }
    
    @objc public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard sections[indexPath.section].items[indexPath.item] is AppearanceSettingsCheckmarkItem else {
            return nil
        }
        return indexPath
    }
    
    @objc public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currentAppTheme = UserDefaults.standard.themeName
        
        if let checkmarkItem = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCheckmarkItem {
            if currentAppTheme.hasPrefix(checkmarkItem.theme) {
                cell.accessoryType = .checkmark
                cell.isSelected = true
            } else {
                cell.accessoryType = .none
                cell.isSelected = false
            }
        }
    }
    
    @objc func applyImageDimmingChange(isOn: NSNumber) {
        let currentTheme = UserDefaults.standard.themeName
        userDidSelect(theme: currentTheme, isImageDimmingEnabled: isOn.boolValue)
        tableView.reloadData()
    }
    
    @objc func handleImageDimmingSwitchValueChange(_ sender: UISwitch) {
        let selector = #selector(applyImageDimmingChange)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(selector, with: NSNumber(value: sender.isOn), afterDelay: CATransaction.animationDuration())
    }
    
    @objc func applyAutomaticTableOpenChange(isOn: NSNumber) {
        UserDefaults.standard.wmf_isAutomaticTableOpeningEnabled = isOn.boolValue
    }
    
    @objc func handleAutomaticTableOpenSwitchValueChange(_ sender: UISwitch) {
        let selector = #selector(applyAutomaticTableOpenChange)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(selector, with: NSNumber(value: sender.isOn), afterDelay: CATransaction.animationDuration())
    }
    
    @objc public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerTitle
    }
    
    @objc public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }

    // MARK: - Themeable

    override public func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.reloadData()
    }
    
}

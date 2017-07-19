import UIKit

protocol AppearanceSettingsItem {
    var title: String? { get }
}

struct AppearanceSettingsSwitchItem: AppearanceSettingsItem {
    let title: String?
    //TODO: change types
    // () -> Bool
    // (Bool) -> Void
    let switchChecker: Bool
    let switchAction: Bool
}

struct AppearanceSettingsCheckmarkItem: AppearanceSettingsItem {
    let title: String?
    //TODO: change types
    // () -> Bool
    // (Bool) -> Void
    let checkmarkChecker: Bool
    let checkmarkAction: Bool
}

struct AppearanceSettingsButtonItem: AppearanceSettingsItem {
    let title: String?
    let buttonAction: () -> Void
}

struct AppearanceSettingsCustomViewItem: AppearanceSettingsItem {
    let title: String?
    let view: UIView
}

struct AppearanceSettingsSection {
    let headerTitle: String
    let footerText: String?
    let items: [AppearanceSettingsItem]
}

@objc(WMFAppearanceSettingsViewController)
//TODO: add Themeable extension
class AppearanceSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections = [AppearanceSettingsSection]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        sections = sectionsForAppearanceSettings()
        print("sections counts: \(sections.count)")
    }
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        
        let readingThemesSection =
            AppearanceSettingsSection(headerTitle: "Reading themes", footerText: nil, items: [AppearanceSettingsCheckmarkItem(title: "Default", checkmarkChecker: false, checkmarkAction: false), AppearanceSettingsCheckmarkItem(title: "Sepia", checkmarkChecker: false, checkmarkAction: false), AppearanceSettingsCheckmarkItem(title: "Dark", checkmarkChecker: false, checkmarkAction: false)])
        
        let themeOptionsSection = AppearanceSettingsSection(headerTitle: "Theme options", footerText: "Automatically apply the ‘Dark’ reading theme between 8pm and 8am", items: [AppearanceSettingsSwitchItem(title: "Image dimming", switchChecker: false, switchAction: false), AppearanceSettingsSwitchItem(title: "Auto-night mode", switchChecker: false, switchAction: false)])
        
        let textSizingSection = AppearanceSettingsSection(headerTitle: "Adjust text sizing", footerText: "Drag the slider above", items: [AppearanceSettingsCustomViewItem(title: nil, view: FontSizeSliderViewController().view)])
        
        return [readingThemesSection, themeOptionsSection, textSizingSection]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        
        let item = sections[indexPath.section].items[indexPath.item]
        cell.title = item.title
        cell.iconName = nil
        
        if let customViewItem = item as? AppearanceSettingsCustomViewItem {
            cell.contentView.addSubview(customViewItem.view)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = sections[indexPath.section].items[indexPath.item] as? AppearanceSettingsCustomViewItem else {
            return tableView.rowHeight
        }
        return item.view.frame.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard sections[indexPath.section].items[indexPath.item] is AppearanceSettingsCheckmarkItem else {
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard sections[indexPath.section].items[indexPath.item] is AppearanceSettingsCheckmarkItem else {
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
    
    func handleImageDimmingSwitchValueChange(_ sender: UISwitch) {
        print("handleImageDimmingSwitchValueChange")
    }
    
    func handleAutoNightModeSwitchValueChange(_ sender: UISwitch) {
        print("handleAutoNightModeSwitchValueChange")
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        //        if let th = header as Themeable? {
        //            th.apply(theme: theme)
        //        }
        header?.text = sections[section].headerTitle
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        //        if let th = header as Themeable? {
        //            th.apply(theme: theme)
        //        }
        footer?.setShortTextAsProse(sections[section].footerText)
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footerText = sections[section].footerText else {
            return 0
        }
        
        let footer = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        footer?.text = footerText
        return footer!.height(withExpectedWidth: self.view.frame.width)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        header?.text = sections[section].headerTitle
        return header!.height(withExpectedWidth: self.view.frame.width)
    }
    
}

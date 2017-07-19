import UIKit

protocol AppearanceSettingsItem {
    var title: String { get }
}

struct AppearanceSettingsSwitchItem: AppearanceSettingsItem {
    let title: String
    //TODO: change types
    // () -> Bool
    // (Bool) -> Void
    let switchChecker: Bool
    let switchAction: Bool
}

struct AppearanceSettingsCheckmarkItem: AppearanceSettingsItem {
    let title: String
    //TODO: change types
    // () -> Bool
    // (Bool) -> Void
    let checkmarkChecker: Bool
    let checkmarkAction: Bool
}

struct AppearanceSettingsButtonItem: AppearanceSettingsItem {
    let title: String
    let buttonAction: () -> Void
}

struct AppearanceSettingsSection {
    let headerTitle: String
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
    }
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        
        let readingThemesSection =
        AppearanceSettingsSection(headerTitle: "Reading themes", items: [AppearanceSettingsCheckmarkItem(title: "Default", checkmarkChecker: false, checkmarkAction: false), AppearanceSettingsCheckmarkItem(title: "Sepia", checkmarkChecker: false, checkmarkAction: false), AppearanceSettingsCheckmarkItem(title: "Dark", checkmarkChecker: false, checkmarkAction: false)])
        
        let themeOptionsSection = AppearanceSettingsSection(headerTitle: "Theme options", items: [AppearanceSettingsSwitchItem(title: "Image dimming", switchChecker: false, switchAction: false), AppearanceSettingsSwitchItem(title: "Auto-night mode", switchChecker: false, switchAction: false)])
        
        return [readingThemesSection, themeOptionsSection]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Appearance sections[section].items.count: \(sections[section].items.count)")
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        let item = sections[indexPath.section].items[indexPath.item]
        cell.title = item.title
        cell.iconName = nil
        
        if let switchItem = item as? AppearanceSettingsSwitchItem {
            cell.disclosureType = .switch
            cell.disclosureSwitch.isOn = false
            cell.disclosureSwitch.addTarget(self, action: #selector(self.handleSwitchValueChange(_:)), for: .valueChanged)
        } else {
            cell.disclosureType = .viewController
        }
        
        return cell
    }
    
    func handleSwitchValueChange(_ sender: UISwitch) {
        print("handleSwitchValueChange")
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
//        if let th = header as Themeable? {
//            th.apply(theme: theme)
//        }
        header?.text = sections[section].headerTitle
        return header;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let header = WMFTableHeaderLabelView.wmf_viewFromClassNib()
        header?.text = sections[section].headerTitle
        return header!.height(withExpectedWidth: self.view.frame.width)
    }

}

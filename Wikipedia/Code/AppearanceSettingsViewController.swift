import UIKit

protocol AppearanceSettingsItem {
    var title: String { get }
}

struct AppearanceSettingsSwitchItem: AppearanceSettingsItem {
    let title: String
    let switchChecker: () -> Bool
    let switchAction: (Bool) -> Void
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
    
    override func viewDidLoad() {
         super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }
    
    func sectionsForAppearanceSettings() -> [AppearanceSettingsSection] {
        return [AppearanceSettingsSection(headerTitle:)]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        return cell
    }

}

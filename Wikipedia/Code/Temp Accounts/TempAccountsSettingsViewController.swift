import UIKit
import WMFComponents

 private struct Section {
    let items: [Item]
    let footerTitle: String
 }

 private struct Item {
    let title: String
    let iconName: String
    let isOn: Bool
    let controlTag: Int
 }

@objc(WMFTempAccountsSettingsViewController)
final class TempAccountsSettingsViewController: SubSettingsViewController, WMFNavigationBarConfiguring {
    private lazy var sections: [Section] = []
    let dataStore: MWKDataStore
    
    @objc
    public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier)
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 44
        reloadSectionData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.tempAccount, customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    private func reloadSectionData() {
        let talkPage = Item(
            title: WMFLocalizedString("settings-temp-accounts-talk-page", value: "Talk page", comment: "Title in Settings > Temporary Account > to view the user's talk page"),
            iconName: "thank",
            isOn: true,
            controlTag: 1)
        let footerTitle = WMFLocalizedString("settings-temp-accounts-talk-page-footer", value: "Temporary account will expire in 90 days", comment: "Footer below temporary account user's talk page, letting them know their account will expire")
        let sections = [Section(items: [talkPage], footerTitle: footerTitle)]
        self.sections = sections
    }
    
    private func getSection(at index: Int) -> Section {
        assert(sections.indices.contains(index), "Section at index \(index) doesn't exist")
        return sections[index]
    }

    private func getItem(at indexPath: IndexPath) -> Item {
        let items = getSection(at: indexPath.section).items
        assert(items.indices.contains(indexPath.row), "Item at indexPath \(indexPath) doesn't exist")
        return items[indexPath.row]
    }
    
    private func showUserTalkPage() {
        let username = dataStore.authenticationManager.authStateTemporaryUsername
        if let siteURL = dataStore.primarySiteURL, let username, let navigationController {
            let userTalkCoordinator = UserTalkCoordinator(navigationController: navigationController, theme: theme, username: username, siteURL: siteURL, dataStore: dataStore)
            userTalkCoordinator.start()
        }
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

// MARK: - Extensions
extension TempAccountsSettingsViewController {
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(at: section)
        return section.items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        let item = getItem(at: indexPath)
        cell.disclosureType = .viewController
        cell.tag = item.controlTag
        cell.iconName = item.iconName
        cell.iconColor = theme.colors.paperBackground
        cell.iconBackgroundColor = WMFColor.blue600
        cell.title = item.title
        cell.apply(theme)
        cell.delegate = self
        return cell
    }
}

extension TempAccountsSettingsViewController {
    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return CommonStrings.tempAccount
    }
}

extension TempAccountsSettingsViewController {
    @objc func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        let text = getSection(at: section).footerTitle
        guard !text.isEmpty else {
            return 0
        }
        
        return UITableView.automaticDimension
    }
    
    @objc func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let text = getSection(at: section).footerTitle
        return WMFTableHeaderFooterLabelView.headerFooterViewForTableView(tableView, text: text, type: .footer, theme: theme)
    }
}

extension TempAccountsSettingsViewController {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = getItem(at: indexPath)
        switch item.controlTag {
        case 1: // Talk Page
            showUserTalkPage()
        default:
            break
        }
    }
}

extension TempAccountsSettingsViewController: WMFSettingsTableViewCellDelegate {
    public func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        let controlTag = settingsTableViewCell.tag
        switch controlTag {
        case 1:
            UserDefaults.standard.wmf_setShowSearchLanguageBar(sender.isOn)
        case 2:
            UserDefaults.standard.wmf_openAppOnSearchTab = sender.isOn
        default:
            break
        }
        reloadSectionData()
    }
}

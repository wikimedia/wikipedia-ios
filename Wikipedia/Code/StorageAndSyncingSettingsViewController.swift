struct SettingsSection {
    let headerTitle: String?
    let footerText: String?
    let items: [SettingsItem]
}

struct SettingsItem {
    let disclosureType: WMFSettingsMenuItemDisclosureType?
    let itemType: StorageAndSyncingSettingsItemType
    let title: String?
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?
    let isSwitchOn: Bool?
    let buttonTitle: String?
}

enum StorageAndSyncingSettingsItemType: Int {
    case syncSavedArticlesAndLists, showSavedReadingList, eraseSavedArticles, syncWithTheServer
    
    public func settingsItem(isSwitchOnByDefault: Bool? = nil) -> SettingsItem {
        var disclosureType: WMFSettingsMenuItemDisclosureType? = nil
        var title: String? = nil
        var isSwitchOn: Bool? = nil
        var buttonTitle: String? = nil
        switch self {
        case .syncSavedArticlesAndLists:
            disclosureType = .switch
            title = WMFLocalizedString("settings-storage-and-syncing-enable-sync-title", value: "Sync saved articles and lists", comment: "Title of the settings option that enables saved articles and reading lists syncing")
            isSwitchOn = isSwitchOnByDefault
        case .showSavedReadingList:
            disclosureType = .switch
            title = WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-title", value: "Show Saved reading list", comment: "Title of the settings option that enables showing the default reading list")
            isSwitchOn = isSwitchOnByDefault
        case .syncWithTheServer:
            disclosureType = .titleButton
            buttonTitle = WMFLocalizedString("settings-storage-and-syncing-server-sync-title", value: "Sync with the server", comment: "Title of the settings button that initiates saved articles and reading lists server sync")
        default:
            break
        }
        
        return SettingsItem(disclosureType: disclosureType, itemType: self, title: title, iconName: nil, iconColor: nil, iconBackgroundColor: nil, isSwitchOn: isSwitchOn, buttonTitle: buttonTitle)
    }
}

@objc(WMFStorageAndSyncingSettingsViewController)
class StorageAndSyncingSettingsViewController: UIViewController {
    private let customViewCellReuseIdentifier = "CustomViewTableViewCell"
    private var theme: Theme = Theme.standard
    private var tableView: UITableView!
    @objc public var dataStore: MWKDataStore?
    private var indexPathsForCellsWithSwitches: [IndexPath] = []
    
    private var sections: [SettingsSection] {
        let syncSavedArticlesAndLists = StorageAndSyncingSettingsItemType.syncSavedArticlesAndLists.settingsItem(isSwitchOnByDefault: isSyncEnabled)
        let showSavedReadingList = StorageAndSyncingSettingsItemType.showSavedReadingList.settingsItem(isSwitchOnByDefault: dataStore?.readingListsController.isDefaultListEnabled)
        let eraseSavedArticles = StorageAndSyncingSettingsItemType.eraseSavedArticles.settingsItem()
        let syncWithTheServer = StorageAndSyncingSettingsItemType.syncWithTheServer.settingsItem()
        
        let syncSavedArticlesAndListsSection = SettingsSection(headerTitle: nil, footerText: WMFLocalizedString("settings-storage-and-syncing-enable-sync-footer-text", value: "Allow Wikimedia to save your saved articles and reading lists to your user preferences when you login to sync", comment: "Footer text of the settings option that enables saved articles and reading lists syncing"), items: [syncSavedArticlesAndLists])
        
        let showSavedReadingListSection = SettingsSection(headerTitle: nil, footerText: WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-footer-text", value: "Show the Saved (eg. default) reading list as a separate list in your Reading lists view. This list appears on Android devices", comment: "Footer text of the settings option that enables showing the default reading list"), items: [showSavedReadingList])
        
        let eraseSavedArticlesSection = SettingsSection(headerTitle: nil, footerText: nil, items: [eraseSavedArticles])
        let syncWithTheServerSection = SettingsSection(headerTitle: nil, footerText: WMFLocalizedString("settings-storage-and-syncing-server-sync-footer-text", value: "Request a sync from the server for an update to your synced articles and reading lists", comment: "Footer text of the settings button that initiates saved articles and reading lists server sync"), items: [syncWithTheServer])
        
        return [syncSavedArticlesAndListsSection, showSavedReadingListSection, eraseSavedArticlesSection, syncWithTheServerSection]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.settingsStorageAndSyncing
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: customViewCellReuseIdentifier)
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        apply(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadRows(at: indexPathsForCellsWithSwitches, with: .none)
    }
    
    private var isSyncEnabled: Bool {
        guard let dataStore = dataStore else {
            return false
        }
        return dataStore.readingListsController.isSyncEnabled
    }
    
    @objc private func eraseSavedArticles() {
        dataStore?.readingListsController.unsaveAllArticles({})
    }
    
    private lazy var eraseSavedArticlesView: EraseSavedArticlesView? = {
        let eraseSavedArticlesView = EraseSavedArticlesView.wmf_viewFromClassNib()
        eraseSavedArticlesView?.titleLabel.text = WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-title", value: "Erase saved articles", comment: "Title of the settings option that enables erasing saved articles")
        eraseSavedArticlesView?.button.setTitle(WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-button-title", value: "Erase", comment: "Title of the settings button that enables erasing saved articles"), for: .normal)
        eraseSavedArticlesView?.button.addTarget(self, action: #selector(eraseSavedArticles), for: .touchUpInside)
        eraseSavedArticlesView?.footerLabel.text = WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-footer-text", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as and from this device.\n\nErasing your saved articles will free up about 364.4 MB of space.", comment: "Footer text of the settings option that enables erasing saved articles")
       return eraseSavedArticlesView
    }()
}

// MARK: UITableViewDataSource

extension StorageAndSyncingSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsItem = sections[indexPath.section].items[indexPath.row]
        
        guard let disclosureType = settingsItem.disclosureType else {
            let cell = tableView.dequeueReusableCell(withIdentifier: customViewCellReuseIdentifier, for: indexPath)
            cell.selectionStyle = .none
            if let eraseSavedArticlesView = eraseSavedArticlesView {
                eraseSavedArticlesView.frame = cell.contentView.bounds
                eraseSavedArticlesView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(eraseSavedArticlesView)
            } else {
                assertionFailure("Couldn't load EraseSavedArticlesView from nib")
            }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        cell.configure(disclosureType, title: settingsItem.title, iconName: settingsItem.iconName, isSwitchOn: settingsItem.isSwitchOn ?? false, iconColor: settingsItem.iconColor, iconBackgroundColor: settingsItem.iconBackgroundColor, buttonTitle: settingsItem.buttonTitle, controlTag: settingsItem.itemType.rawValue, theme: theme)
    
        if settingsItem.disclosureType == .switch {
            indexPathsForCellsWithSwitches.append(indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }
}

// MARK: - UITableViewDelegate

extension StorageAndSyncingSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let settingsItem = sections[indexPath.section].items[indexPath.row]
        guard settingsItem.disclosureType != nil else {
            return eraseSavedArticlesView?.frame.height ?? 0
        }
        return tableView.rowHeight
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension StorageAndSyncingSettingsViewController: WMFSettingsTableViewCellDelegate {
    
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        guard let settingsItemType = StorageAndSyncingSettingsItemType(rawValue: sender.tag) else {
            assertionFailure("Toggled discloure switch of WMFSettingsTableViewCell for undefined StorageAndSyncingSettingsItemType")
            return
        }
        
        switch settingsItemType {
        case .syncSavedArticlesAndLists:
            if WMFAuthenticationManager.sharedInstance.loggedInUsername == nil && !isSyncEnabled {
                wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: theme, dismissHandler: { sender.setOn(false, animated: true) })
            } else {
                dataStore?.readingListsController.setSyncEnabled(sender.isOn, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: !sender.isOn)
            }
        case .showSavedReadingList:
            dataStore?.readingListsController.isDefaultListEnabled = sender.isOn
        default:
            return
        }
    }
    
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didPress sender: UIButton!) {
        guard let settingsItemType = StorageAndSyncingSettingsItemType(rawValue: sender.tag), settingsItemType == .syncWithTheServer else {
            assertionFailure("Pressed button of WMFSettingsTableViewCell for undefined StorageAndSyncingSettingsItemType")
            return
        }
        
        dataStore?.readingListsController.fullSync({})
    }
}

// MARK: Themeable

extension StorageAndSyncingSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
        eraseSavedArticlesView?.apply(theme: theme)
    }
}

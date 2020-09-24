private struct Section {
    let type: ItemType
    let footerText: String?
    let items: [Item]
    
    init(for type: ItemType, with items: [Item]) {
        
        var footerText: String? = nil
        
        switch type {
        case .syncSavedArticlesAndLists:
            footerText = WMFLocalizedString("settings-storage-and-syncing-enable-sync-footer-text", value: "Allow Wikimedia to save your saved articles and reading lists to your user preferences when you login and sync.", comment: "Footer text of the settings option that enables saved articles and reading lists syncing")
        case .showSavedReadingList:
            footerText = WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-footer-text", value: "Show the Saved (eg. default) reading list as a separate list in your reading lists view. This list appears on Android devices.", comment: "Footer text of the settings option that enables showing the default reading list")
        case .syncWithTheServer:
            footerText = WMFLocalizedString("settings-storage-and-syncing-server-sync-footer-text", value: "Request an update to your synced articles and reading lists.", comment: "Footer text of the settings button that initiates saved articles and reading lists server sync")
        default:
            break
        }
        
        self.type = type
        self.footerText = footerText
        self.items = items
    }
}

private struct Item {
    let disclosureType: WMFSettingsMenuItemDisclosureType?
    let type: ItemType
    let title: String
    let isSwitchOn: Bool
    
    init(for type: ItemType, isSwitchOn: Bool = false) {
        self.type = type
        self.isSwitchOn = isSwitchOn
        
        var disclosureType: WMFSettingsMenuItemDisclosureType? = nil
        let title: String

        switch type {
        case .syncSavedArticlesAndLists:
            disclosureType = .switch
            title = WMFLocalizedString("settings-storage-and-syncing-enable-sync-title", value: "Sync saved articles and lists", comment: "Title of the settings option that enables saved articles and reading lists syncing")
        case .showSavedReadingList:
            disclosureType = .switch
            title = WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-title", value: "Show Saved reading list", comment: "Title of the settings option that enables showing the default reading list")
        case .syncWithTheServer:
            disclosureType = .titleButton
            title = WMFLocalizedString("settings-storage-and-syncing-server-sync-title", value: "Update synced reading lists", comment: "Title of the settings button that initiates saved articles and reading lists server sync")
        default:
            title = ""
            break
        }
        
        self.title = title
        self.disclosureType = disclosureType
    }
}

private enum ItemType: Int {
    case syncSavedArticlesAndLists, showSavedReadingList, eraseSavedArticles, syncWithTheServer
}

@objc(WMFStorageAndSyncingSettingsViewController)
class StorageAndSyncingSettingsViewController: SubSettingsViewController {
    @objc public var dataStore: MWKDataStore?
    private var indexPathForCellWithSyncSwitch: IndexPath?
    private var shouldShowReadingListsSyncAlertWhenViewAppears = false
    private var shouldShowReadingListsSyncAlertWhenSyncEnabled = false
    
    private var sections: [Section] {
        let syncSavedArticlesAndLists = Item(for: .syncSavedArticlesAndLists, isSwitchOn: isSyncEnabled)
        let showSavedReadingList = Item(for: .showSavedReadingList, isSwitchOn: dataStore?.readingListsController.isDefaultListEnabled ?? false)
        let eraseSavedArticles = Item(for: .eraseSavedArticles)
        let syncWithTheServer = Item(for: .syncWithTheServer)
        
        let syncSavedArticlesAndListsSection = Section(for: .syncSavedArticlesAndLists, with: [syncSavedArticlesAndLists])
        let showSavedReadingListSection = Section(for: .showSavedReadingList, with: [showSavedReadingList])
        let eraseSavedArticlesSection = Section(for: .eraseSavedArticles, with: [eraseSavedArticles])
        let syncWithTheServerSection = Section(for: .syncWithTheServer, with: [syncWithTheServer])
        
        return [syncSavedArticlesAndListsSection, showSavedReadingListSection, eraseSavedArticlesSection, syncWithTheServerSection]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.settingsStorageAndSyncing
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier)
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 44
        NotificationCenter.default.addObserver(self, selector: #selector(readingListsServerDidConfirmSyncWasEnabledForAccount(notification:)), name: ReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard shouldShowReadingListsSyncAlertWhenViewAppears else {
            return
        }
        if isSyncEnabled {
            showReadingListsSyncAlert()
        } else { // user logged in to an account that has sync disabled, prompt them to enable sync
            
            wmf_showEnableReadingListSyncPanel(theme: theme, oncePerLogin: false, didNotPresentPanelCompletion: nil) {
                self.shouldShowReadingListsSyncAlertWhenSyncEnabled = true
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }
    
    private func showReadingListsSyncAlert() {
        wmf_showAlertWithMessage(WMFLocalizedString("settings-storage-and-syncing-full-sync", value: "Your reading lists will be synced in the background", comment: "Message confirming to the user that their reading lists will be synced in the background"))
    }
    
    @objc private func readingListsServerDidConfirmSyncWasEnabledForAccount(notification: Notification) {
        if let indexPathForCellWithSyncSwitch = indexPathForCellWithSyncSwitch {
            tableView.reloadRows(at: [indexPathForCellWithSyncSwitch], with: .none)
        }
        guard shouldShowReadingListsSyncAlertWhenSyncEnabled else {
            return
        }
        if isSyncEnabled {
            showReadingListsSyncAlert()
        }
    }
    
    private var isSyncEnabled: Bool {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return false
        }
        return dataStore.readingListsController.isSyncEnabled
    }
    
    @objc private func eraseSavedArticles() {
        let alert = UIAlertController(title: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-alert-title", value: "Erase all saved articles?", comment: "Title of the alert shown before erasing all saved article."), message: WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-alert-message", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as from this device. You cannot undo this action.", comment: "Message for the alert shown before erasing all saved articles."), preferredStyle: .alert)
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        let erase = UIAlertAction(title: CommonStrings.eraseAllSavedArticles, style: .destructive) { (_) in
            guard let dataStore = self.dataStore else {
                assertionFailure("dataStore is nil")
                return
            }
            
            dataStore.readingListsController.eraseAllSavedArticlesAndReadingLists()
            self.tableView.reloadData()
        }
        alert.addAction(cancel)
        alert.addAction(erase)
        present(alert, animated: true)
    }
    
    private lazy var eraseSavedArticlesView: EraseSavedArticlesView? = {
        let eraseSavedArticlesView = EraseSavedArticlesView.wmf_viewFromClassNib()
        eraseSavedArticlesView?.titleLabel.text = CommonStrings.eraseAllSavedArticles
        eraseSavedArticlesView?.button.setTitle(WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-button-title", value: "Erase", comment: "Title of the settings button that enables erasing saved articles"), for: .normal)
        eraseSavedArticlesView?.button.addTarget(self, action: #selector(eraseSavedArticles), for: .touchUpInside)
        eraseSavedArticlesView?.updateFonts()
       return eraseSavedArticlesView
    }()

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground
        eraseSavedArticlesView?.apply(theme: theme)
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource

extension StorageAndSyncingSettingsViewController {
    private func getItem(at indexPath: IndexPath) -> Item {
        return sections[indexPath.section].items[indexPath.row]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsItem = getItem(at: indexPath)
        
        guard let disclosureType = settingsItem.disclosureType else {
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
            cell.selectionStyle = .none
            cell.backgroundColor = theme.colors.paperBackground
            if let eraseSavedArticlesView = eraseSavedArticlesView {
                let cacheSize = CacheController.totalCacheSizeInBytes
                let dataSizeString = ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file)
                let format = WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-footer-text", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as from this device.\n\nErasing your saved articles will free up about %1$@ of space.", comment: "Footer text of the settings option that enables erasing saved articles. %1$@ will be replaced with a number and a system provided localized unit indicator for MB or KB.")
                eraseSavedArticlesView.footerLabel.text = String.localizedStringWithFormat(format, dataSizeString)
                eraseSavedArticlesView.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.wmf_addSubviewWithConstraintsToEdges(eraseSavedArticlesView)
            } else {
                assertionFailure("Couldn't load EraseSavedArticlesView from nib")
            }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        cell.configure(disclosureType, disclosureText: nil, title: settingsItem.title, subtitle: nil, iconName: nil, isSwitchOn: settingsItem.isSwitchOn, iconColor: nil, iconBackgroundColor: nil, controlTag: settingsItem.type.rawValue, theme: theme)
    
        if settingsItem.type == .syncSavedArticlesAndLists {
            indexPathForCellWithSyncSwitch = indexPath
        }
        
        return cell
    }
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = getItem(at: indexPath)
        switch item.type {
        case .syncWithTheServer:
            let loginSuccessCompletion = {
                self.dataStore?.readingListsController.fullSync({})
                self.shouldShowReadingListsSyncAlertWhenViewAppears = true
            }
            let isLoggedIn = dataStore?.authenticationManager.isLoggedIn ?? false
            if isLoggedIn && isSyncEnabled {
                dataStore?.readingListsController.fullSync({})
                showReadingListsSyncAlert()
            } else if !isLoggedIn {
                wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: theme, dismissHandler: nil, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: nil)
            } else {
                wmf_showEnableReadingListSyncPanel(theme: theme, oncePerLogin: false, didNotPresentPanelCompletion: nil) {
                    self.shouldShowReadingListsSyncAlertWhenSyncEnabled = true
                }
            }
        default:
            break
        }
    }
}

// MARK: UITableViewDelegate

extension StorageAndSyncingSettingsViewController {
    @objc func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: WMFTableHeaderFooterLabelView.identifier) as? WMFTableHeaderFooterLabelView else {
            return nil
        }
        footer.setShortTextAsProse(sections[section].footerText)
        footer.type = .footer
        if let footer = footer as Themeable? {
            footer.apply(theme: theme)
        }
        return footer
    }
    
    @objc func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let _ = self.tableView(tableView, viewForFooterInSection: section) as? WMFTableHeaderFooterLabelView else {
            return 0
        }
        return UITableView.automaticDimension
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension StorageAndSyncingSettingsViewController: WMFSettingsTableViewCellDelegate {
    
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        guard let settingsItemType = ItemType(rawValue: sender.tag) else {
            assertionFailure("Toggled discloure switch of WMFSettingsTableViewCell for undefined StorageAndSyncingSettingsItemType")
            return
        }
        
        guard let dataStore = self.dataStore else {
            return
        }
        
        let isSwitchOn = sender.isOn
        
        switch settingsItemType {
        case .syncSavedArticlesAndLists where !dataStore.authenticationManager.isLoggedIn:
            assert(!isSyncEnabled, "Sync cannot be enabled if user is not logged in")
            let dismissHandler = {
                sender.setOn(false, animated: true)
            }
            let loginSuccessCompletion: () -> Void = {
                dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                SettingsFunnel.shared.logSyncEnabledInSettings()
            }
            wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: theme, dismissHandler: dismissHandler, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: dismissHandler)
        case .syncSavedArticlesAndLists where dataStore.authenticationManager.isLoggedIn:
            let setSyncEnabled = {
                dataStore.readingListsController.setSyncEnabled(isSwitchOn, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: !isSwitchOn)
                if isSwitchOn {
                    SettingsFunnel.shared.logSyncEnabledInSettings()
                } else {
                    SettingsFunnel.shared.logSyncDisabledInSettings()
                }
            }
            if !isSwitchOn {
                self.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .syncDisabled, theme: self.theme) {
                    setSyncEnabled()
                }
            } else {
                setSyncEnabled()
            }
        case .showSavedReadingList:
            dataStore.readingListsController.isDefaultListEnabled = isSwitchOn
        default:
            return
        }
    }
}

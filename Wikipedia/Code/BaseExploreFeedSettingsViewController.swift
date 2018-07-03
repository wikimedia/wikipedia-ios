protocol ExploreFeedSettingsItem {
    var title: String { get }
    var subtitle: String? { get }
    var disclosureType: WMFSettingsMenuItemDisclosureType { get }
    var disclosureText: String? { get }
    var iconName: String? { get }
    var iconColor: UIColor? { get }
    var iconBackgroundColor: UIColor? { get }
    var controlTag: Int { get }
    var isOn: Bool { get }
    func updateSubtitle(for displayType: ExploreFeedSettingsDisplayType)
    func updateDisclosureText(for displayType: ExploreFeedSettingsDisplayType)
    func updateIsOn(for displayType: ExploreFeedSettingsDisplayType)
}

extension ExploreFeedSettingsSwitchItem {
    var subtitle: String? { return nil }
    var disclosureType: WMFSettingsMenuItemDisclosureType { return .switch }
    var disclosureText: String? { return nil }
    var iconName: String? { return nil }
    var iconColor: UIColor? { return nil }
    var iconBackgroundColor: UIColor? { return nil }
}

struct ExploreFeedSettingsSection {
    let headerTitle: String?
    let footerTitle: String
    let items: [ExploreFeedSettingsItem]
}

struct ExploreFeedSettingsLanguage: ExploreFeedSettingsSwitchItem {
    let title: String
    let subtitle: String?
    let controlTag: Int
    let isOn: Bool
    let siteURL: URL

    init(_ languageLink: MWKLanguageLink, controlTag: Int, isOn: Bool) {
        title = languageLink.localizedName
        subtitle = languageLink.languageCode.uppercased()
        self.controlTag = controlTag
        self.isOn = isOn
        siteURL = languageLink.siteURL()
    }
}

struct ExploreFeedSettingsGlobalCards: ExploreFeedSettingsSwitchItem {
    let disclosureType: WMFSettingsMenuItemDisclosureType = .switch
    let title: String = WMFLocalizedString("explore-feed-preferences-global-cards-title", value: "Global cards", comment: "Title for the setting that allows users to toggle non-language specific feed cards")
    let subtitle: String? = WMFLocalizedString("explore-feed-preferences-global-cards-description", value: "Non-language specific cards", comment: "Description of global feed cards")
    let controlTag: Int = -2
    let isOn: Bool = SessionSingleton.sharedInstance().dataStore.feedContentController.areGlobalContentGroupKindsInFeed
}

struct ExploreFeedSettingsMaster: ExploreFeedSettingsSwitchItem {
    let title: String
    let controlTag: Int = -1
    let isOn: Bool

    init(title: String, isOn: Bool) {
        self.title = title
        self.isOn = isOn
    }
}

class BaseExploreFeedSettingsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @objc var dataStore: MWKDataStore?
    var theme = Theme.standard
    var indexPathsForCellsThatNeedReloading: [IndexPath] = []

    override var nibName: String? {
        return "BaseExploreFeedSettingsViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier)
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        tableView.sectionFooterHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionFooterHeight = 44
        apply(theme: theme)
        NotificationCenter.default.addObserver(self, selector: #selector(exploreFeedPreferencesDidSave(_:)), name: NSNotification.Name.WMFExploreFeedPreferencesDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newExploreFeedPreferencesWereRejected(_:)), name: NSNotification.Name.WMFNewExploreFeedPreferencesWereRejected, object: nil)
    }

    var preferredLanguages: [MWKLanguageLink] {
        return MWKLanguageLinkController.sharedInstance().preferredLanguages
    }

    var languages: [ExploreFeedSettingsLanguage] {
        let languages = preferredLanguages.enumerated().compactMap { (index, languageLink) in
            ExploreFeedSettingsLanguage(languageLink, controlTag: index, isOn: isLanguageSwitchOn(for: languageLink))
        }
        return languages
    }

    var feedContentController: WMFExploreFeedContentController? {
        return dataStore?.feedContentController
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open func needsReloading(_ item: ExploreFeedSettingsItem) -> Bool {
        assertionFailure("Subclassers should override")
        return false
    }

    open var shouldReload: Bool {
        return true
    }

    open func isLanguageSwitchOn(for languageLink: MWKLanguageLink) -> Bool {
        assertionFailure("Subclassers should override")
        return false
    }

    open var sections: [ExploreFeedSettingsSection] {
        assertionFailure("Subclassers should override")
        return []
    }

    func getItem(at indexPath: IndexPath) -> ExploreFeedSettingsItem {
        let items = getSection(at: indexPath.section).items
        assert(items.indices.contains(indexPath.row), "Item at indexPath \(indexPath) doesn't exist")
        return items[indexPath.row]
    }

    func getSection(at index: Int) -> ExploreFeedSettingsSection {
        assert(sections.indices.contains(index), "Section at index \(index) doesn't exist")
        return sections[index]
    }

    // MARK: - Notifications

    open func reload() {
        guard shouldReload else {
            return
        }
    }

    @objc open func exploreFeedPreferencesDidSave(_ notification: Notification) {
        DispatchQueue.main.async {
            self.reload()
        }
    }

    @objc open func newExploreFeedPreferencesWereRejected(_ notification: Notification) {
        DispatchQueue.main.async {
            self.reload()
        }
    }

}

// MARK: - UITableViewDataSource

extension BaseExploreFeedSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(at: section)
        return section.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        let item = getItem(at: indexPath)
        if let switchItem = item as? ExploreFeedSettingsSwitchItem {
            configureSwitch(cell, switchItem: switchItem)
        } else {
            cell.configure(item.disclosureType, disclosureText: item.disclosureText, title: item.title, subtitle: item.subtitle, iconName: item.iconName, iconColor: item.iconColor, iconBackgroundColor: item.iconBackgroundColor, theme: theme)
        }
        if needsReloading(item) {
            indexPathsForCellsThatNeedReloading.append(indexPath)
        }
        return cell
    }

    private func configureSwitch(_ cell: WMFSettingsTableViewCell, switchItem: ExploreFeedSettingsSwitchItem) {
        cell.configure(switchItem.disclosureType, disclosureText: switchItem.disclosureText, title: switchItem.title, subtitle: switchItem.subtitle, iconName: switchItem.iconName, isSwitchOn: switchItem.isOn, iconColor: switchItem.iconColor, iconBackgroundColor: switchItem.iconBackgroundColor, controlTag: switchItem.controlTag, theme: theme)
        cell.delegate = self
    }
}

// MARK: - UITableViewDelegate

extension BaseExploreFeedSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = getSection(at: section)
        return section.headerTitle
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: WMFTableHeaderFooterLabelView.identifier) as? WMFTableHeaderFooterLabelView else {
            return nil
        }
        let section = getSection(at: section)
        footer.setShortTextAsProse(section.footerTitle)
        footer.type = .footer
        if let footer = footer as Themeable? {
            footer.apply(theme: theme)
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let _ = self.tableView(tableView, viewForFooterInSection: section) as? WMFTableHeaderFooterLabelView else {
            return 0
        }
        return UITableViewAutomaticDimension
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension BaseExploreFeedSettingsViewController: WMFSettingsTableViewCellDelegate {
    open func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        assertionFailure("Subclassers should override")
    }
}

// MARK: - Themeable

extension BaseExploreFeedSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
    }
}

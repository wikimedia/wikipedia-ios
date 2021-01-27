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

extension ExploreFeedSettingsItem {
    var subtitle: String? { return nil }
    var disclosureType: WMFSettingsMenuItemDisclosureType { return .switch }
    var disclosureText: String? { return nil }
    var iconName: String? { return nil }
    var iconColor: UIColor? { return nil }
    var iconBackgroundColor: UIColor? { return nil }
    func updateSubtitle(for displayType: ExploreFeedSettingsDisplayType) {

    }
    func updateDisclosureText(for displayType: ExploreFeedSettingsDisplayType) {

    }
    func updateIsOn(for displayType: ExploreFeedSettingsDisplayType) {
        
    }
}

enum ExploreFeedSettingsMainType: Equatable {
    case entireFeed
    case singleFeedCard(WMFContentGroupKind)
}

private extension WMFContentGroupKind {
    var switchTitle: String {
        switch self {
        case .news:
            return WMFLocalizedString("explore-feed-preferences-show-news-title", value: "Show In the news card", comment: "Text for the setting that allows users to toggle the visibility of the In the news card")
        case .featuredArticle:
            return WMFLocalizedString("explore-feed-preferences-show-featured-article-title", value: "Show Featured article card", comment: "Text for the setting that allows users to toggle the visibility of the Featured article card")
        case .topRead:
            return WMFLocalizedString("explore-feed-preferences-show-top-read-title", value: "Show Top read card", comment: "Text for the setting that allows users to toggle the visibility of the Top read card")
        case .onThisDay:
            return WMFLocalizedString("explore-feed-preferences-show-on-this-day-title", value: "Show On this day card", comment: "Text for the setting that allows users to toggle the visibility of the On this day card")
        case .pictureOfTheDay:
            return WMFLocalizedString("explore-feed-preferences-show-picture-of-the-day-title", value: "Show Picture of the day card", comment: "Text for the setting that allows users to toggle the visibility of the Picture of the day card")
        case .locationPlaceholder:
            fallthrough
        case .location:
            return WMFLocalizedString("explore-feed-preferences-show-places-title", value: "Show Places card", comment: "Text for the setting that allows users to toggle the visibility of the Places card")
        case .random:
            return WMFLocalizedString("explore-feed-preferences-show-randomizer-title", value: "Show Randomizer card", comment: "Text for the setting that allows users to toggle the visibility of the Randomizer card")
        case .continueReading:
            return WMFLocalizedString("explore-feed-preferences-show-continue-reading-title", value: "Show Continue reading card", comment: "Text for the setting that allows users to toggle the visibility of the Continue reading card")
        case .relatedPages:
            return WMFLocalizedString("explore-feed-preferences-show-related-pages-title", value: "Show Because you read card", comment: "Text for the setting that allows users to toggle the visibility of the Because you read card")
        default:
            assertionFailure("\(self) is not customizable")
            return ""
        }
    }
}

class ExploreFeedSettingsPrimary: ExploreFeedSettingsItem {
    let title: String
    let controlTag: Int = -1
    var isOn: Bool = false
    let type: ExploreFeedSettingsMainType

    init(for type: ExploreFeedSettingsMainType) {
        self.type = type
        if case let .singleFeedCard(contentGroupKind) = type {
            title = contentGroupKind.switchTitle
            isOn = contentGroupKind.isInFeed
        } else {
            title = WMFLocalizedString("explore-feed-preferences-explore-tab", value: "Explore tab", comment: "Text for the setting that allows users to toggle whether the Explore tab is enabled or not")
            isOn = UserDefaults.standard.defaultTabType == .explore
        }
    }

    func updateIsOn(for displayType: ExploreFeedSettingsDisplayType) {
        if case let .singleFeedCard(contentGroupKind) = type {
            isOn = contentGroupKind.isInFeed
        } else {
            isOn = UserDefaults.standard.defaultTabType == .explore
        }
    }
}

struct ExploreFeedSettingsSection {
    let headerTitle: String?
    let footerTitle: String
    let items: [ExploreFeedSettingsItem]
}

class ExploreFeedSettingsLanguage: ExploreFeedSettingsItem {
    let title: String
    let subtitle: String?
    let controlTag: Int
    var isOn: Bool = false
    let siteURL: URL
    let languageLink: MWKLanguageLink

    init(_ languageLink: MWKLanguageLink, controlTag: Int, displayType: ExploreFeedSettingsDisplayType) {
        self.languageLink = languageLink
        title = languageLink.localizedName
        subtitle = languageLink.contentLanguageCode.uppercased()
        self.controlTag = controlTag
        siteURL = languageLink.siteURL
        updateIsOn(for: displayType)
    }

    func updateIsOn(for displayType: ExploreFeedSettingsDisplayType) {
        switch (displayType) {
        case .singleLanguage:
            return
        case .multipleLanguages:
            isOn = languageLink.isInFeed
        case .detail(let contentGroupKind):
            isOn = languageLink.isInFeed(for: contentGroupKind)
        }
    }
}

class ExploreFeedSettingsGlobalCards: ExploreFeedSettingsItem {
    let disclosureType: WMFSettingsMenuItemDisclosureType = .switch
    let title: String = WMFLocalizedString("explore-feed-preferences-global-cards-title", value: "Global cards", comment: "Title for the setting that allows users to toggle non-language specific feed cards")
    let subtitle: String? = WMFLocalizedString("explore-feed-preferences-global-cards-description", value: "Non-language specific cards", comment: "Description of global feed cards")
    let controlTag: Int = -2
    var isOn: Bool = MWKDataStore.shared().feedContentController.areGlobalContentGroupKindsInFeed

    func updateIsOn(for displayType: ExploreFeedSettingsDisplayType) {
        guard displayType == .singleLanguage || displayType == .multipleLanguages else {
            return
        }
        isOn = MWKDataStore.shared().feedContentController.areGlobalContentGroupKindsInFeed
    }
}

enum ExploreFeedSettingsDisplayType: Equatable {
    case singleLanguage
    case multipleLanguages
    case detail(WMFContentGroupKind)
}

class BaseExploreFeedSettingsViewController: SubSettingsViewController {
    @objc var dataStore: MWKDataStore?

    open var displayType: ExploreFeedSettingsDisplayType = .singleLanguage
    var activeSwitch: UISwitch?

    var updateFeedBeforeViewDisappears: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier)
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 44
        NotificationCenter.default.addObserver(self, selector: #selector(exploreFeedPreferencesDidSave(_:)), name: NSNotification.Name.WMFExploreFeedPreferencesDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newExploreFeedPreferencesWereRejected(_:)), name: NSNotification.Name.WMFNewExploreFeedPreferencesWereRejected, object: nil)
    }

    var preferredLanguages: [MWKLanguageLink] {
        return MWKDataStore.shared().languageLinkController.preferredLanguages
    }

    lazy var languages: [ExploreFeedSettingsLanguage] = {
        let languages = preferredLanguages.enumerated().compactMap { (index, languageLink) in
            ExploreFeedSettingsLanguage(languageLink, controlTag: index, displayType: self.displayType)
        }
        return languages
    }()

    var feedContentController: WMFExploreFeedContentController? {
        return dataStore?.feedContentController
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open var sections: [ExploreFeedSettingsSection] {
        assertionFailure("Subclassers should override")
        return []
    }

    lazy var itemsGroupedByIndexPaths: [IndexPath: ExploreFeedSettingsItem] = {
        var dictionary = [IndexPath: ExploreFeedSettingsItem]()
        for (sectionIndex, section) in sections.enumerated() {
            for (itemIndex, item) in section.items.enumerated() {
                dictionary[IndexPath(row: itemIndex, section: sectionIndex)] = item
            }
        }
        return dictionary
    }()

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

    private func reload() {
        for (indexPath, item) in itemsGroupedByIndexPaths {
            item.updateIsOn(for: displayType)
            item.updateDisclosureText(for: displayType)
            item.updateSubtitle(for: displayType)
            guard let cell = tableView.cellForRow(at: indexPath) as? WMFSettingsTableViewCell else {
                continue
            }
            cell.disclosureSwitch.setOn(item.isOn, animated: true)
            cell.disclosureText = item.disclosureText
            cell.subtitle = item.subtitle
        }
    }

    @objc private func exploreFeedPreferencesDidSave(_ notification: Notification) {
        updateFeedBeforeViewDisappears = true
        DispatchQueue.main.async {
            self.reload()
        }
    }

    @objc private func newExploreFeedPreferencesWereRejected(_ notification: Notification) {
        guard let activeSwitch = activeSwitch else {
            return
        }
        activeSwitch.setOn(!activeSwitch.isOn, animated: true)
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground
        if viewIfLoaded?.window != nil {
            tableView.reloadData()
        }
    }

}

// MARK: - UITableViewDataSource

extension BaseExploreFeedSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(at: section)
        return section.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        let item = getItem(at: indexPath)
        configureCell(cell, item: item)
        return cell
    }

    private func configureCell(_ cell: WMFSettingsTableViewCell, item: ExploreFeedSettingsItem) {
        cell.configure(item.disclosureType, disclosureText: item.disclosureText, title: item.title, subtitle: item.subtitle, iconName: item.iconName, isSwitchOn: item.isOn, iconColor: item.iconColor, iconBackgroundColor: item.iconBackgroundColor, controlTag: item.controlTag, theme: theme)
        cell.delegate = self
    }
}

// MARK: - UITableViewDelegate

extension BaseExploreFeedSettingsViewController {
    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = getSection(at: section)
        return section.headerTitle
    }

    @objc func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
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

    @objc func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let _ = self.tableView(tableView, viewForFooterInSection: section) as? WMFTableHeaderFooterLabelView else {
            return 0
        }
        return UITableView.automaticDimension
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension BaseExploreFeedSettingsViewController: WMFSettingsTableViewCellDelegate {
    open func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        assertionFailure("Subclassers should override")
    }
}

// MARK: - MWKLanguageLink Convenience Methods

fileprivate extension MWKLanguageLink {
    private var feedContentController: WMFExploreFeedContentController {
        MWKDataStore.shared().feedContentController
    }
    
    /**
     Flag indicating whether there are any visible customizable feed content sources in this language.
     Returns true if there is at least one content source in this language visible in the feed.
     Returns false if there are no content sources in this language visible in the feed.
     */
    var isInFeed: Bool {
        feedContentController.anyContentGroupsVisibleInTheFeed(forSiteURL: siteURL)
    }
    
    /**
     Flag indicating whether the content group of given kind is visible in the feed in this language.
     Returns YES if the content group of given kind is visible in the feed in this language.
     Returns NO if the content group of given kind is not visible in the feed in this language.
     */
    func isInFeed(for contentGroupKind: WMFContentGroupKind) -> Bool {
        feedContentController.contentLanguageCodes(for: contentGroupKind).contains(contentLanguageCode)
    }
}

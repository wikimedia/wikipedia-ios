import UIKit

private struct Section {
    let headerTitle: String?
    let footerTitle: String
    let items: [Item]
}

private protocol Item {
    var title: String { get }
    var disclosureType: WMFSettingsMenuItemDisclosureType { get }
    var discloureText: String? { get }
    var type: ItemType { get }
    var iconName: String? { get }
    var iconColor: UIColor? { get }
    var iconBackgroundColor: UIColor? { get }
}

private protocol SwitchItem: Item {
    var controlTag: Int { get }
    var isOn: Bool { get }
}

extension SwitchItem {
    var disclosureType: WMFSettingsMenuItemDisclosureType { return .switch }
    var discloureText: String? { return nil }
    var iconName: String? { return nil }
    var iconColor: UIColor? { return nil }
    var iconBackgroundColor: UIColor? { return nil }
}

private struct Master: SwitchItem {
    let title: String
    let type: ItemType = .masterSwitch
    let controlTag: Int = -1
    let isOn: Bool
    
}

private struct Language: SwitchItem {
    let title: String
    let type: ItemType
    let controlTag: Int
    let isOn: Bool
    let siteURL: URL

    init(_ languageLink: MWKLanguageLink, controlTag: Int) {
        type = ItemType.language(languageLink)
        title = languageLink.localizedName
        self.controlTag = controlTag
        isOn = languageLink.isInFeed
        siteURL = languageLink.siteURL()
    }
}

private enum ItemType {
    case masterSwitch
    case language(MWKLanguageLink)
}

class FeedCardSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private var dataStore: MWKDataStore?
    private var contentGroupKind: WMFContentGroupKind = .unknown
    private var theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedSectionFooterHeight = UITableViewAutomaticDimension
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier())
    }

    func configure(with title: String, dataStore: MWKDataStore?, contentGroupKind: WMFContentGroupKind, theme: Theme) {
        self.title = title
        self.dataStore = dataStore
        self.contentGroupKind = contentGroupKind
        self.theme = theme
        apply(theme: theme)
    }

    private lazy var languages: [Language] = { // maybe a set
        let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
        let languages = preferredLanguages.enumerated().compactMap { (index, languageLink) in
            Language(languageLink, controlTag: index)
        }
        return languages
    }()

    private lazy var sections: [Section] = {
        let master = Master(title: "Show in the news card", isOn: true)
        let main = Section(headerTitle: nil, footerTitle: "Turning off the In the news card will turn the card off in all available languages.", items: [master])
        let languages = Section(headerTitle: "Languages", footerTitle: "Additional languages can be added in the ‘My languages’ settings page. Turning off all available languages will turn off the In the news card.", items: self.languages)
        return [main, languages]
    }()

    private func getItem(at indexPath: IndexPath) -> Item {
        let items = getSection(at: indexPath.section).items
        assert(items.indices.contains(indexPath.row), "Item at indexPath \(indexPath) doesn't exist")
        return items[indexPath.row]
    }

    private func getSection(at index: Int) -> Section {
        assert(sections.indices.contains(index), "Section at index \(index) doesn't exist")
        return sections[index]
    }

}

extension FeedCardSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(at: section)
        return section.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        let item = getItem(at: indexPath)
        if let switchItem = item as? SwitchItem {
            configureSwitch(cell, switchItem: switchItem)
        }
        return cell
    }

    private func configureSwitch(_ cell: WMFSettingsTableViewCell, switchItem: SwitchItem) {
        cell.configure(.switch, title: switchItem.title, iconName: switchItem.iconName, isSwitchOn: switchItem.isOn, iconColor: switchItem.iconColor, iconBackgroundColor: switchItem.iconBackgroundColor, controlTag: switchItem.controlTag, theme: theme)
        cell.delegate = self
    }
}

extension FeedCardSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = getSection(at: section)
        return section.headerTitle
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: WMFTableHeaderFooterLabelView.identifier()) as? WMFTableHeaderFooterLabelView else {
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
}

// MARK: - Themeable

extension FeedCardSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension FeedCardSettingsViewController: WMFSettingsTableViewCellDelegate {
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        let controlTag = sender.tag
        guard let feedContentController = dataStore?.feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        guard controlTag != -1 else { // master switch
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn)
            return
        }
        guard let language = languages.first(where: { $0.controlTag == sender.tag }) else {
            assertionFailure("No language for a given control tag")
            return
        }
        feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn, forSiteURL: language.siteURL)
    }
}

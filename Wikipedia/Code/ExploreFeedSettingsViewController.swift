import UIKit

private struct Section {
    let headerTitle: String
    let footerTitle: String
    let items: [Item]
}

private protocol Item {
    var title: String { get }
    var subtitle: String? { get }
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
    var subtitle: String? { return nil }
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

    init(title: String) {
        self.title = title
        isOn = false
    }
}

private struct FeedCard: Item {
    let title: String
    let subtitle: String?
    let disclosureType: WMFSettingsMenuItemDisclosureType
    let discloureText: String?
    let type: ItemType
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?

    init(contentGroupKind: WMFContentGroupKind) {
        type = ItemType.feedCard(contentGroupKind)

        let languageCodes = SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: contentGroupKind)

        let disclosureTextString: () -> String = {
            let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
            if (languageCodes.count == preferredLanguages.count) {
                return "On all"
            } else {
                return "On \(languageCodes.count)"
            }
        }

        subtitle = languageCodes.joined(separator: ", ").uppercased()
        disclosureType = .viewControllerWithDisclosureText
        discloureText = disclosureTextString()

        switch contentGroupKind {
        case .news:
            title = CommonStrings.inTheNewsTitle
            iconName = "in-the-news-mini"
            iconColor = UIColor.wmf_lightGray
            iconBackgroundColor = UIColor.wmf_lighterGray
        case .onThisDay:
            title = "On this day"
            iconName = "on-this-day-mini"
            iconColor = UIColor.wmf_blue
            iconBackgroundColor = UIColor.wmf_lightBlue
        case .featuredArticle:
            title = "Featured article"
            iconName = "featured-mini"
            iconColor = UIColor.wmf_yellow
            iconBackgroundColor = UIColor.wmf_lightYellow
        case .topRead:
            title = "Top read"
            iconName = "trending-mini"
            iconColor = UIColor.wmf_blue
            iconBackgroundColor = UIColor.wmf_lightBlue
        case .pictureOfTheDay:
            title = "Picture of the day"
            iconName = "potd-mini"
            iconColor = UIColor.wmf_purple
            iconBackgroundColor = UIColor.wmf_lightPurple
        case .location:
            title = "Places"
            iconName = "nearby-mini"
            iconColor = UIColor.wmf_green
            iconBackgroundColor = UIColor.wmf_lightGreen
        case .random:
            title = "Randomizer"
            iconName = "random-mini"
            iconColor = UIColor.wmf_red
            iconBackgroundColor = UIColor.wmf_lightRed
        default:
            assertionFailure("Group of kind \(contentGroupKind) is not customizable")
            title = ""
            iconName = nil
            iconColor = nil
            iconBackgroundColor = nil
        }
    }
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
    case feedCard(WMFContentGroupKind)
    case language(MWKLanguageLink)
    case masterSwitch
}

@objc(WMFExploreFeedSettingsViewController)
class ExploreFeedSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @objc var dataStore: MWKDataStore?
    private var theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore feed"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.backTitle, style: .plain, target: nil, action: nil)
        tableView.estimatedSectionFooterHeight = UITableViewAutomaticDimension
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier())
        apply(theme: theme)
    }

    private lazy var languages: [Language] = { // maybe a set
        let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
        let languages = preferredLanguages.enumerated().compactMap { (index, languageLink) in
            Language(languageLink, controlTag: index)
        }
        return languages
    }()

    private var sections: [Section] {
        let inTheNews = FeedCard(contentGroupKind: .news)
        let onThisDay = FeedCard(contentGroupKind: .onThisDay)
        let featuredArticle = FeedCard(contentGroupKind: .featuredArticle)
        let topRead = FeedCard(contentGroupKind: .topRead)
        let pictureOfTheDay = FeedCard(contentGroupKind: .pictureOfTheDay)
        let places = FeedCard(contentGroupKind: .location) // ?
        let randomizer = FeedCard(contentGroupKind: .random)
        let customization = Section(headerTitle: "Customize the Explore feed", footerTitle: "Hiding an card type will stop this card type from appearing in the Explore feed. Hiding all Explore feed cards will turn off the Explore tab. ", items: [inTheNews, onThisDay, featuredArticle, topRead, pictureOfTheDay, places, randomizer])

        let languages = Section(headerTitle: "Languages", footerTitle: "Hiding all Explore feed cards in all of your languages will turn off the Explore Tab.", items: self.languages)

        let master = Master(title: "Turn off Explore tab")
        let main = Section(headerTitle: nil, footerTitle: "Turning off the Explore tab will replace the Explore tab with a Settings tab. ", items: [master])

        return [customization, languages, main]

    private func getItem(at indexPath: IndexPath) -> Item {
        return sections[indexPath.section].items[indexPath.row]
    }

    private func getSection(at index: Int) -> Section {
        assert(sections.indices.contains(index), "Section at index \(index) doesn't exist")
        return sections[index]
    }
}

extension ExploreFeedSettingsViewController: UITableViewDataSource {
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
        } else {
            cell.configure(item.disclosureType, disclosureText: item.discloureText, title: item.title, subtitle: item.subtitle, iconName: item.iconName, iconColor: item.iconColor, iconBackgroundColor: item.iconBackgroundColor, theme: theme)
        }
        return cell
    }

    private func configureSwitch(_ cell: WMFSettingsTableViewCell, switchItem: SwitchItem) {
        cell.configure(.switch, title: switchItem.title, iconName: switchItem.iconName, isSwitchOn: switchItem.isOn, iconColor: switchItem.iconColor, iconBackgroundColor: switchItem.iconBackgroundColor, controlTag: switchItem.controlTag, theme: theme)
        cell.delegate = self
    }
}

// MARK: - UITableViewDelegate

extension ExploreFeedSettingsViewController: UITableViewDelegate {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = getItem(at: indexPath)
        switch item.type {
        case .feedCard(let contentGroupKind):
            let feedCardSettingsViewController = FeedCardSettingsViewController()
            feedCardSettingsViewController.configure(with: item.title, dataStore: dataStore, contentGroupKind: contentGroupKind, theme: theme)
            navigationController?.pushViewController(feedCardSettingsViewController, animated: true)
        default:
            assertionFailure()
        }
    }
}

// MARK: - Themeable

extension ExploreFeedSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension ExploreFeedSettingsViewController: WMFSettingsTableViewCellDelegate {
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        guard let language = languages.first(where: { $0.controlTag == sender.tag }) else {
            assertionFailure("No language for a given control tag")
            return
        }
        guard let feedContentController = dataStore?.feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        feedContentController.toggleContent(forSiteURL: language.siteURL, isOn: sender.isOn, updateFeed: true)
    }
}

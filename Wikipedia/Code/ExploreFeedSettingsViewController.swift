import UIKit

private struct Section {
    let headerTitle: String
    let footerTitle: String
    let items: [Item]
}

private struct Item {
    let title: String
    let disclosureType: WMFSettingsMenuItemDisclosureType
    let separatorInset: UIEdgeInsets
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?

    init(type: ItemType) {
        switch type {
        case .inTheNews:
            title = "In the news"
            disclosureType = .viewController
            separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            iconName = "in-the-news-mini"
            iconColor = UIColor(red: 0.639, green: 0.663, blue: 0.690, alpha: 1.0)
            iconBackgroundColor = UIColor.wmf_lighterGray
        case .onThisDay:
            title = "On this day"
            disclosureType = .viewController
            separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            iconName = "on-this-day-mini"
            iconColor = UIColor(red: 0.243, green: 0.243, blue: 0.773, alpha: 1.0)
            iconBackgroundColor = UIColor(red: 0.922, green: 0.953, blue: 0.996, alpha: 1.0)
        case .language(let name):
            title = name
            disclosureType = .switch
            separatorInset = .zero
            iconName = nil
            iconColor = nil
            iconBackgroundColor = nil
        default:
            title = "In the news"
            disclosureType = .viewController
            separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            iconName = "in-the-news-mini"
            iconColor = UIColor(red: 0.639, green: 0.663, blue: 0.690, alpha: 1.0)
            iconBackgroundColor = UIColor.wmf_lighterGray
        }
    }
}

private enum ItemType {
    case inTheNews
    case onThisDay
    case continueReading
    case becauseYouRead
    case featuredArticle
    case topRead
    case pictureOfTheDay
    case places
    case randomizer
    case language(String)
}

@objc(WMFExploreFeedSettingsViewController)
class ExploreFeedSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore feed"
        tableView.estimatedSectionFooterHeight = UITableViewAutomaticDimension
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier())
        apply(theme: theme)
    }

    private var sections: [Section] {
        let inTheNews = Item(type: .inTheNews)
        let onThisDay = Item(type: .onThisDay)
        let customization = Section(headerTitle: "Customize the Explore feed", footerTitle: "Hiding an card type will stop this card type from appearing in the Explore feed. Hiding all Explore feed cards will turn off the Explore tab. ", items: [inTheNews, onThisDay])

        let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
        let preferredLanguagesNames = preferredLanguages.compactMap { $0.localizedName }
        let items = preferredLanguagesNames.compactMap { Item(type: .language($0)) }
        let languages = Section(headerTitle: "Languages", footerTitle: "Hiding all Explore feed cards in all of your languages will turn off the Explore Tab.", items: items)

        return [customization, languages]
    }

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
        cell.configure(item.disclosureType, separatorInset: item.separatorInset, title: item.title, iconName: item.iconName, iconColor: item.iconColor, iconBackgroundColor: item.iconBackgroundColor, theme: theme)
        return cell
    }
}

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
}

extension ExploreFeedSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
    }
}

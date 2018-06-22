import UIKit

private struct FeedCard: ExploreFeedSettingsSwitchItem {
    let title: String
    let subtitle: String?
    let disclosureType: WMFSettingsMenuItemDisclosureType
    let disclosureText: String?
    let type: ExploreFeedSettingsItemType
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?
    var controlTag: Int = 0
    var isOn: Bool = true

    init(contentGroupKind: WMFContentGroupKind, displayType: DisplayType) {
        type = ExploreFeedSettingsItemType.feedCard(contentGroupKind)

        let languageCodes = SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: contentGroupKind)

        let disclosureTextString: () -> String = {
            let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
            if (languageCodes.count == preferredLanguages.count) {
                return "On all"
            } else if languageCodes.count > 0 {
                return "On \(languageCodes.count)"
            } else {
                return "Off"
            }
        }

        var feedCardDescription: String?

        switch contentGroupKind {
        case .news:
            title = CommonStrings.inTheNewsTitle
            feedCardDescription = "Articles about current events"
            iconName = "in-the-news-mini"
            iconColor = UIColor.wmf_lightGray
            iconBackgroundColor = UIColor.wmf_lighterGray
        case .onThisDay:
            title = "On this day"
            feedCardDescription = "Events in history on this day"
            iconName = "on-this-day-mini"
            iconColor = UIColor.wmf_blue
            iconBackgroundColor = UIColor.wmf_lightBlue
        case .featuredArticle:
            title = "Featured article"
            feedCardDescription = "Daily featured article on Wikipedia"
            iconName = "featured-mini"
            iconColor = UIColor.wmf_yellow
            iconBackgroundColor = UIColor.wmf_lightYellow
        case .topRead:
            title = "Top read"
            feedCardDescription = "Daily most read articles"
            iconName = "trending-mini"
            iconColor = UIColor.wmf_blue
            iconBackgroundColor = UIColor.wmf_lightBlue
        case .pictureOfTheDay:
            title = "Picture of the day"
            feedCardDescription = "Daily featured image from Commons"
            iconName = "potd-mini"
            iconColor = UIColor.wmf_purple
            iconBackgroundColor = UIColor.wmf_lightPurple
        case .location:
            title = "Places"
            feedCardDescription = "Wikipedia articles near your location"
            iconName = "nearby-mini"
            iconColor = UIColor.wmf_green
            iconBackgroundColor = UIColor.wmf_lightGreen
        case .random:
            title = "Randomizer"
            feedCardDescription = "Generate random artilces to read"
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

        if displayType == .singleLanguage {
            subtitle = feedCardDescription
            disclosureType = .switch
            disclosureText = nil
            controlTag = Int(contentGroupKind.rawValue)
            isOn = contentGroupKind.isInFeed
        } else {
            subtitle = languageCodes.joined(separator: ", ").uppercased()
            disclosureType = .viewControllerWithDisclosureText
            disclosureText = disclosureTextString()
        }
    }
}

private enum DisplayType {
    case singleLanguage
    case multipleLanguages
}

@objc(WMFExploreFeedSettingsViewController)
class ExploreFeedSettingsViewController: BaseExploreFeedSettingsViewController {

    private var didToggleMasterSwitch = false

    private lazy var displayType: DisplayType = {
        assert(preferredLanguages.count > 0)
        return preferredLanguages.count == 1 ? .singleLanguage : .multipleLanguages
    }()

    override var shouldReload: Bool {
        return !didToggleMasterSwitch
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore feed"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.backTitle, style: .plain, target: nil, action: nil)
    }

    override func needsReloading(_ item: ExploreFeedSettingsItem) -> Bool {
        return item is FeedCard
    }

    override func isLanguageSwitchOn(for languageLink: MWKLanguageLink) -> Bool {
        return languageLink.isInFeed
    }

    override var sections: [ExploreFeedSettingsSection] {
        let inTheNews = FeedCard(contentGroupKind: .news, displayType: displayType)
        let onThisDay = FeedCard(contentGroupKind: .onThisDay, displayType: displayType)
        let featuredArticle = FeedCard(contentGroupKind: .featuredArticle, displayType: displayType)
        let topRead = FeedCard(contentGroupKind: .topRead, displayType: displayType)
        let pictureOfTheDay = FeedCard(contentGroupKind: .pictureOfTheDay, displayType: displayType)
        let places = FeedCard(contentGroupKind: .location, displayType: displayType)
        let randomizer = FeedCard(contentGroupKind: .random, displayType: displayType)
        let customization = ExploreFeedSettingsSection(headerTitle: "Customize the Explore feed", footerTitle: "Hiding an card type will stop this card type from appearing in the Explore feed. Hiding all Explore feed cards will turn off the Explore tab. ", items: [inTheNews, onThisDay, featuredArticle, topRead, pictureOfTheDay, places, randomizer])

        let languages = ExploreFeedSettingsSection(headerTitle: "Languages", footerTitle: "Hiding all Explore feed cards in all of your languages will turn off the Explore Tab.", items: self.languages)

        let master = ExploreFeedSettingsMaster(title: "Turn off Explore tab", isOn: feedContentController?.mainTabType != .explore)
        let main = ExploreFeedSettingsSection(headerTitle: nil, footerTitle: "Turning off the Explore tab will replace the Explore tab with a Settings tab. ", items: [master])

        let sections = displayType == .singleLanguage ? [customization, main] : [customization, languages, main]
        return sections
    }
}

// MARK: - UITableViewDelegate

extension ExploreFeedSettingsViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = getItem(at: indexPath)
        switch item.type {
        case .feedCard(let contentGroupKind):
            let feedCardSettingsViewController = FeedCardSettingsViewController(nibName: "BaseExploreFeedSettingsViewController", bundle: nil)
            feedCardSettingsViewController.configure(with: item.title, dataStore: dataStore, contentGroupKind: contentGroupKind, theme: theme)
            navigationController?.pushViewController(feedCardSettingsViewController, animated: true)
        default:
            return
        }
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension ExploreFeedSettingsViewController {
    override func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        let controlTag = sender.tag
        guard let feedContentController = feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        guard controlTag != -1 else { // master switch
            didToggleMasterSwitch = true
            feedContentController.changeMainTab(to: sender.isOn ? .settings : .explore)
            return
        }
        if displayType == .singleLanguage {
            let customizable = WMFExploreFeedContentController.customizableContentGroupKindNumbers()
            guard let contentGroupKindNumber = customizable.first(where: { $0.intValue == controlTag }), let contentGroupKind = WMFContentGroupKind(rawValue: contentGroupKindNumber.int32Value) else {
                assertionFailure("No content group kind card for a given control tag")
                return
            }
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn)
        } else {
            guard let language = languages.first(where: { $0.controlTag == controlTag }) else {
                assertionFailure("No language for a given control tag")
                return
            }
            feedContentController.toggleContent(forSiteURL: language.siteURL, isOn: sender.isOn, updateFeed: true)
        }
    }
}

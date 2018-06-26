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
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-in-the-news-description", value: "Articles about current events", comment: "Description of In the news section of Explore feed")
            iconName = "in-the-news-mini"
            iconColor = UIColor.wmf_lightGray
            iconBackgroundColor = UIColor.wmf_lighterGray
        case .onThisDay:
            title = CommonStrings.onThisDayTitle
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-on-this-day-description", value: "Events in history on this day", comment: "Description of On this day section of Explore feed")
            iconName = "on-this-day-mini"
            iconColor = UIColor.wmf_blue
            iconBackgroundColor = UIColor.wmf_lightBlue
        case .featuredArticle:
            title = "Featured article"
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-featured-article-description", value: "Daily featured article on Wikipedia", comment: "Description of Featured article section of Explore feed")
            iconName = "featured-mini"
            iconColor = UIColor.wmf_yellow
            iconBackgroundColor = UIColor.wmf_lightYellow
        case .topRead:
            title = CommonStrings.topReadTitle
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-top-read-description", value: "Daily most read articles", comment: "Description of Top read section of Explore feed")
            iconName = "trending-mini"
            iconColor = UIColor.wmf_blue
            iconBackgroundColor = UIColor.wmf_lightBlue
        case .pictureOfTheDay:
            title = CommonStrings.pictureOfTheDayTitle
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-picture-of-the-day-description", value: "Daily featured image from Commons", comment: "Description of Picture of the day section of Explore feed")
            iconName = "potd-mini"
            iconColor = UIColor.wmf_purple
            iconBackgroundColor = UIColor.wmf_lightPurple
        case .location:
            title = CommonStrings.placesTabTitle
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-places-description", value: "Wikipedia articles near your location", comment: "Description of Places section of Explore feed")
            iconName = "nearby-mini"
            iconColor = UIColor.wmf_green
            iconBackgroundColor = UIColor.wmf_lightGreen
        case .random:
            title = CommonStrings.randomizerTitle
            feedCardDescription = WMFLocalizedString("explore-feed-preferences-randomizer-description", value: "Generate random artilces to read", comment: "Description of Randomizer section of Explore feed")

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

        let master = ExploreFeedSettingsMaster(title: "Turn off Explore tab", isOn: feedContentController?.isDefaultTabExplore ?? false)
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
            feedContentController.changeDefaultTab(to: sender.isOn ? .settings : .explore)
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

import UIKit

private class FeedCard: ExploreFeedSettingsSwitchItem {
    let contentGroupKind: WMFContentGroupKind
    let title: String
    var subtitle: String?
    let disclosureType: WMFSettingsMenuItemDisclosureType
    var disclosureText: String? = nil
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?
    var controlTag: Int = 0
    var isOn: Bool = true

    init(contentGroupKind: WMFContentGroupKind, displayType: DisplayType) {
        self.contentGroupKind = contentGroupKind

        var singleLanguageDescription: String?

        switch contentGroupKind {
        case .news:
            title = CommonStrings.inTheNewsTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-in-the-news-description", value: "Articles about current events", comment: "Description of In the news section of Explore feed")
            iconName = "in-the-news-mini"
            iconColor = .wmf_lightGray
            iconBackgroundColor = .wmf_lighterGray
        case .onThisDay:
            title = CommonStrings.onThisDayTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-on-this-day-description", value: "Events in history on this day", comment: "Description of On this day section of Explore feed")
            iconName = "on-this-day-mini"
            iconColor = .wmf_blue
            iconBackgroundColor = .wmf_lightBlue
        case .featuredArticle:
            title = "Featured article"
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-featured-article-description", value: "Daily featured article on Wikipedia", comment: "Description of Featured article section of Explore feed")
            iconName = "featured-mini"
            iconColor = .wmf_yellow
            iconBackgroundColor = .wmf_lightYellow
        case .topRead:
            title = CommonStrings.topReadTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-top-read-description", value: "Daily most read articles", comment: "Description of Top read section of Explore feed")
            iconName = "trending-mini"
            iconColor = .wmf_blue
            iconBackgroundColor = .wmf_lightBlue
        case .location:
            fallthrough
        case .locationPlaceholder:
            title = CommonStrings.placesTabTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-places-description", value: "Wikipedia articles near your location", comment: "Description of Places section of Explore feed")
            iconName = "nearby-mini"
            iconColor = .wmf_green
            iconBackgroundColor = .wmf_lightGreen
        case .random:
            title = CommonStrings.randomizerTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-randomizer-description", value: "Generate random articles to read", comment: "Description of Randomizer section of Explore feed")
            iconName = "random-mini"
            iconColor = .wmf_red
            iconBackgroundColor = .wmf_lightRed
        case .pictureOfTheDay:
            title = CommonStrings.pictureOfTheDayTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-potd-description", value: "Daily featured image from Commons", comment: "Description of Picture of the day section of Explore feed")
            iconName = "potd-mini"
            iconColor = .wmf_purple
            iconBackgroundColor = .wmf_lightPurple
        case .continueReading:
            title = "Continue reading"
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-continue-reading-description", value: "Quick link back to reading an open article", comment: "Description of Continue reading section of Explore feed")
            iconName = "today-mini"
            iconColor = .wmf_lightGray
            iconBackgroundColor = .wmf_lighterGray
        case .relatedPages:
            title = CommonStrings.relatedPagesTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-related-pages-description", value: "Suggestions based on reading history", comment: "Description of Related pages section of Explore feed")
            iconName = "recent-mini"
            iconColor = .wmf_lightGray
            iconBackgroundColor = .wmf_lighterGray
        default:
            assertionFailure("Group of kind \(contentGroupKind) is not customizable")
            title = ""
            iconName = nil
            iconColor = nil
            iconBackgroundColor = nil
        }

        if displayType == .singleLanguage {
            subtitle = singleLanguageDescription
            disclosureType = .switch
            controlTag = Int(contentGroupKind.rawValue)
            isOn = contentGroupKind.isInFeed
        } else {
            disclosureType = .viewControllerWithDisclosureText
            disclosureText = multipleLanguagesDisclosureText(for: contentGroupKind)
            subtitle = multipleLanguagesSubtitle(for: contentGroupKind)
        }
    }

    private func multipleLanguagesDisclosureText(for contentGroupKind: WMFContentGroupKind) -> String {
        guard contentGroupKind.isGlobal else {
            let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
            let languageCodes = contentGroupKind.languageCodes
            switch languageCodes.count {
            case preferredLanguages.count:
                return CommonStrings.onAllTitle
            case 1...:
                return CommonStrings.onTitle(languageCodes.count)
            default:
                return CommonStrings.offTitle
            }
        }
        if contentGroupKind.isInFeed {
            return CommonStrings.onTitle
        } else {
            return CommonStrings.offTitle
        }
    }

    func updateIsOn(for displayType: DisplayType) {
        guard displayType == .singleLanguage else {
            return
        }
        isOn = contentGroupKind.isInFeed
    }

    func updateDisclosureText(for displayType: DisplayType) {
        guard displayType == .multipleLanguages else {
            return
        }
        disclosureText = multipleLanguagesDisclosureText(for: contentGroupKind)
    }

    private func multipleLanguagesSubtitle(for contentGroupKind: WMFContentGroupKind) -> String {
        if contentGroupKind.isGlobal {
            return WMFLocalizedString("explore-feed-preferences-global-cards-subtitle", value: "Not language specific", comment: "Subtitle desribing non-language specific feed cards")
        } else {
            return contentGroupKind.languageCodes.joined(separator: ", ").uppercased()
        }
    }

    func updateSubtitle(for displayType: DisplayType) {
        guard displayType == .multipleLanguages else {
            return
        }
        subtitle = multipleLanguagesSubtitle(for: contentGroupKind)
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
        return displayType == .multipleLanguages && !didToggleMasterSwitch
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.exploreFeedTitle
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.backTitle, style: .plain, target: nil, action: nil)
    }

    override func needsReloading(_ item: ExploreFeedSettingsItem) -> Bool {
        return item is FeedCard || item is ExploreFeedSettingsGlobalCards
    }

    override func reload() {
        for feedCard in feedCards {
            feedCard.updateDisclosureText(for: displayType)
            feedCard.updateSubtitle(for: displayType)
        }
        tableView.reloadRows(at: indexPathsForCellsThatNeedReloading, with: .none)
    }

    override func isLanguageSwitchOn(for languageLink: MWKLanguageLink) -> Bool {
        return languageLink.isInFeed
    }

    private lazy var feedCards: [FeedCard] = {
        let inTheNews = FeedCard(contentGroupKind: .news, displayType: displayType)
        let onThisDay = FeedCard(contentGroupKind: .onThisDay, displayType: displayType)
        let featuredArticle = FeedCard(contentGroupKind: .featuredArticle, displayType: displayType)
        let topRead = FeedCard(contentGroupKind: .topRead, displayType: displayType)
        let places = FeedCard(contentGroupKind: WMFLocationManager.isAuthorized() ? .location : .locationPlaceholder, displayType: displayType)
        let randomizer = FeedCard(contentGroupKind: .random, displayType: displayType)
        let pictureOfTheDay = FeedCard(contentGroupKind: .pictureOfTheDay, displayType: displayType)
        let continueReading = FeedCard(contentGroupKind: .continueReading, displayType: displayType)
        let relatedPages = FeedCard(contentGroupKind: .relatedPages, displayType: displayType)
        return [inTheNews, onThisDay, featuredArticle, topRead, places, randomizer, pictureOfTheDay, continueReading, relatedPages]
    }()

    override var sections: [ExploreFeedSettingsSection] {
        let togglingFeedCardsFooterText = WMFLocalizedString("explore-feed-preferences-languages-footer-text", value: "Hiding all Explore feed cards in all of your languages will turn off the Explore tab.", comment: "Text for explaining the effects of hiding all feed cards")

        let customization = ExploreFeedSettingsSection(headerTitle: WMFLocalizedString("explore-feed-preferences-customize-explore-feed", value: "Customize the Explore feed", comment: "Title of the Settings section that allows users to customize the Explore feed"), footerTitle: String.localizedStringWithFormat("%@ %@", WMFLocalizedString("explore-feed-preferences-customize-explore-feed-footer-text", value: "Hiding a card type will stop this card type from appearing in the Explore feed.", comment: "Text for explaining the effects of hiding feed cards"), togglingFeedCardsFooterText), items: feedCards)

        var languageItems: [ExploreFeedSettingsItem] = self.languages
        languageItems.append(ExploreFeedSettingsGlobalCards())
        let languages = ExploreFeedSettingsSection(headerTitle: CommonStrings.languagesTitle, footerTitle: togglingFeedCardsFooterText, items: languageItems)

        let master = ExploreFeedSettingsMaster(title: WMFLocalizedString("explore-feed-preferences-turn-off-feed", value: "Turn off Explore tab", comment: "Text for the setting that allows users to turn off Explore tab"), isOn: UserDefaults.wmf_userDefaults().defaultTabType != .explore)
        let main = ExploreFeedSettingsSection(headerTitle: nil, footerTitle: WMFLocalizedString("explore-feed-preferences-turn-off-feed-disclosure", value: "Turning off the Explore tab will replace the Explore tab with a Settings tab.", comment: "Text for explaining the effects of turning off the Explore tab"), items: [master])

        if displayType == .singleLanguage {
            return [customization, main]
        } else {
            return [customization, languages, main]
        }
    }
}

// MARK: - UITableViewDelegate

extension ExploreFeedSettingsViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard displayType == .multipleLanguages else {
            return
        }
        let item = getItem(at: indexPath)
        guard let feedCard = item as? FeedCard else {
            return
        }
        let feedCardSettingsViewController = FeedCardSettingsViewController()
        feedCardSettingsViewController.configure(with: item.title, dataStore: dataStore, contentGroupKind: feedCard.contentGroupKind, theme: theme)
        navigationController?.pushViewController(feedCardSettingsViewController, animated: true)
        self.tableView.deselectRow(at: indexPath, animated: true)
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
            UserDefaults.wmf_userDefaults().defaultTabType = sender.isOn ? .settings : .explore
            return
        }
        guard controlTag != -2 else { // global cards
            feedContentController.toggleGlobalContentGroupKinds(sender.isOn)
            return
        }
        if displayType == .singleLanguage {
            guard let contentGroupKind = WMFContentGroupKind(rawValue: Int32(controlTag)) else {
                assertionFailure("No content group kind for given control tag")
                return
            }
            guard contentGroupKind.isCustomizable || contentGroupKind.isGlobal else {
                assertionFailure("Content group kind \(contentGroupKind) is not customizable nor global")
                return
            }
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn)
        } else {
            guard let language = languages.first(where: { $0.controlTag == controlTag }) else {
                assertionFailure("No language for given control tag")
                return
            }
            feedContentController.toggleContent(forSiteURL: language.siteURL, isOn: sender.isOn, updateFeed: true)
        }
    }
}

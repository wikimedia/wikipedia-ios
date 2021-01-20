import UIKit

private class FeedCard: ExploreFeedSettingsItem {
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

    init(contentGroupKind: WMFContentGroupKind, displayType: ExploreFeedSettingsDisplayType) {
        self.contentGroupKind = contentGroupKind

        var singleLanguageDescription: String?

        switch contentGroupKind {
        case .news:
            title = CommonStrings.inTheNewsTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-in-the-news-description", value: "Articles about current events", comment: "Description of In the news section of Explore feed")
            iconName = "in-the-news-mini"
            iconColor = .base50
            iconBackgroundColor = .base80
        case .onThisDay:
            title = CommonStrings.onThisDayTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-on-this-day-description", value: "Events in history on this day", comment: "Description of On this day section of Explore feed")
            iconName = "on-this-day-mini"
            iconColor = .accent50
            iconBackgroundColor = .accent90
        case .featuredArticle:
            title = CommonStrings.featuredArticleTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-featured-article-description", value: "Daily featured article on Wikipedia", comment: "Description of Featured article section of Explore feed")
            iconName = "featured-mini"
            iconColor = .yellow50
            iconBackgroundColor = .yellow90
        case .topRead:
            title = CommonStrings.topReadTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-top-read-description", value: "Daily most read articles", comment: "Description of Top read section of Explore feed")
            iconName = "trending-mini"
            iconColor = .accent50
            iconBackgroundColor = .accent90
        case .location:
            fallthrough
        case .locationPlaceholder:
            title = CommonStrings.placesTabTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-places-description", value: "Wikipedia articles near your location", comment: "Description of Places section of Explore feed")
            iconName = "nearby-mini"
            iconColor = .green50
            iconBackgroundColor = .green90
        case .random:
            title = CommonStrings.randomizerTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-randomizer-description", value: "Generate random articles to read", comment: "Description of Randomizer section of Explore feed")
            iconName = "random-mini"
            iconColor = .red50
            iconBackgroundColor = .red90
        case .pictureOfTheDay:
            title = CommonStrings.pictureOfTheDayTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-potd-description", value: "Daily featured image from Commons", comment: "Description of Picture of the day section of Explore feed")
            iconName = "potd-mini"
            iconColor = .purple50
            iconBackgroundColor = .purple90
        case .continueReading:
            title = CommonStrings.continueReadingTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-continue-reading-description", value: "Quick link back to reading an open article", comment: "Description of Continue reading section of Explore feed")
            iconName = "today-mini"
            iconColor = .base50
            iconBackgroundColor = .base80
        case .relatedPages:
            title = CommonStrings.relatedPagesTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-related-pages-description", value: "Suggestions based on reading history", comment: "Description of Related pages section of Explore feed")
            iconName = "recent-mini"
            iconColor = .base50
            iconBackgroundColor = .base80
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
            let preferredLanguages = MWKDataStore.shared().languageLinkController.preferredLanguages
            let contentLanguageCodes = contentGroupKind.contentLanguageCodes
            switch contentLanguageCodes.count {
            case preferredLanguages.count:
                return CommonStrings.onAllTitle
            case 1...:
                return CommonStrings.onTitle(contentLanguageCodes.count)
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

    func updateIsOn(for displayType: ExploreFeedSettingsDisplayType) {
        guard displayType == .singleLanguage else {
            return
        }
        isOn = contentGroupKind.isInFeed
    }

    func updateDisclosureText(for displayType: ExploreFeedSettingsDisplayType) {
        guard displayType == .multipleLanguages else {
            return
        }
        disclosureText = multipleLanguagesDisclosureText(for: contentGroupKind)
    }

    private func multipleLanguagesSubtitle(for contentGroupKind: WMFContentGroupKind) -> String {
        if contentGroupKind.isGlobal {
            return WMFLocalizedString("explore-feed-preferences-global-cards-subtitle", value: "Not language specific", comment: "Subtitle describing non-language specific feed cards")
        } else {
            let contentLanguageCodes = contentGroupKind.contentLanguageCodes
            let preferredContentLanguageCodes = MWKDataStore.shared().languageLinkController.preferredLanguages.map { $0.contentLanguageCode }
            let filteredLanguages = preferredContentLanguageCodes.filter { contentLanguageCodes.contains($0) }
            return filteredLanguages.joined(separator: ", ").uppercased()
        }
    }

    func updateSubtitle(for displayType: ExploreFeedSettingsDisplayType) {
        guard displayType == .multipleLanguages else {
            return
        }
        subtitle = multipleLanguagesSubtitle(for: contentGroupKind)
    }
}

@objc(WMFExploreFeedSettingsViewController)
class ExploreFeedSettingsViewController: BaseExploreFeedSettingsViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if updateFeedBeforeViewDisappears {
            feedContentController?.updateFeedSourcesUserInitiated(true)
        }
    }

    public var showCloseButton = false {
        didSet {
            if showCloseButton {
                navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(closeButtonPressed))
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.exploreFeedTitle
        assert(!preferredLanguages.isEmpty)
        displayType = preferredLanguages.count == 1 ? .singleLanguage : .multipleLanguages
    }

    @objc private func closeButtonPressed() {
        dismiss(animated: true)
    }

    // MARK: Items

    private lazy var feedCards: [FeedCard] = {
        let inTheNews = FeedCard(contentGroupKind: .news, displayType: displayType)
        let onThisDay = FeedCard(contentGroupKind: .onThisDay, displayType: displayType)
        let featuredArticle = FeedCard(contentGroupKind: .featuredArticle, displayType: displayType)
        let topRead = FeedCard(contentGroupKind: .topRead, displayType: displayType)
        let places = FeedCard(contentGroupKind: .location, displayType: displayType)
        let randomizer = FeedCard(contentGroupKind: .random, displayType: displayType)
        let pictureOfTheDay = FeedCard(contentGroupKind: .pictureOfTheDay, displayType: displayType)
        let continueReading = FeedCard(contentGroupKind: .continueReading, displayType: displayType)
        let relatedPages = FeedCard(contentGroupKind: .relatedPages, displayType: displayType)
        return [inTheNews, onThisDay, featuredArticle, topRead, places, randomizer, pictureOfTheDay, continueReading, relatedPages]
    }()

    private lazy var globalCards: ExploreFeedSettingsGlobalCards = {
        return ExploreFeedSettingsGlobalCards()
    }()

    // MARK: Sections

    let togglingFeedCardsFooterText = WMFLocalizedString("explore-feed-preferences-languages-footer-text", value: "Hiding all Explore feed cards in all of your languages will turn off the Explore tab.", comment: "Text for explaining the effects of hiding all feed cards")

    private lazy var customizationSection: ExploreFeedSettingsSection = {
        return ExploreFeedSettingsSection(headerTitle: WMFLocalizedString("explore-feed-preferences-customize-explore-feed", value: "Customize the Explore feed", comment: "Title of the Settings section that allows users to customize the Explore feed"), footerTitle: String.localizedStringWithFormat("%@ %@", WMFLocalizedString("explore-feed-preferences-customize-explore-feed-footer-text", value: "Hiding a card type will stop this card type from appearing in the Explore feed.", comment: "Text for explaining the effects of hiding feed cards"), togglingFeedCardsFooterText), items: feedCards)
    }()

    private lazy var mainSection: ExploreFeedSettingsSection = {
        return ExploreFeedSettingsSection(headerTitle: nil, footerTitle: WMFLocalizedString("explore-feed-preferences-turn-off-feed-disclosure", value: "Turning off the Explore tab will replace the Explore tab with a Settings tab.", comment: "Text for explaining the effects of turning off the Explore tab"), items: [ExploreFeedSettingsPrimary(for: .entireFeed)])
    }()

    private lazy var languagesSection: ExploreFeedSettingsSection? = {
        guard displayType == .multipleLanguages else {
            return nil
        }
        var items: [ExploreFeedSettingsItem] = languages
        items.append(globalCards)
        return ExploreFeedSettingsSection(headerTitle: CommonStrings.languagesTitle, footerTitle: togglingFeedCardsFooterText, items: items)
    }()

    override var sections: [ExploreFeedSettingsSection] {
        guard displayType == .multipleLanguages else {
            return [customizationSection, mainSection]
        }
        guard let languagesSection = languagesSection else {
            return [customizationSection, mainSection]
        }
        return [customizationSection, languagesSection, mainSection]
    }

    // MARK: Toggling Explore feed

    private func turnOnExploreAlertController(turnedOn: @escaping () -> Void, cancelled: @escaping () -> Void) -> UIAlertController {
        let alertController = UIAlertController(title: CommonStrings.turnOnExploreTabTitle, message: WMFLocalizedString("explore-feed-preferences-turn-on-explore-tab-message", value: "This will replace the Settings tab with the Explore tab, you can access Settings from the top of the Explore tab by tapping on the gear icon", comment: "Message for alert that allows users to turn on the Explore tab"), preferredStyle: .alert)
        let turnOnExplore = UIAlertAction(title: CommonStrings.turnOnExploreActionTitle, style: .default, handler: { _ in
            turnedOn()
        })
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in
            cancelled()
        })
        alertController.addAction(turnOnExplore)
        alertController.addAction(cancel)
        return alertController
    }

    private func turnOffExploreAlertController(turnedOff: @escaping () -> Void, cancelled: @escaping () -> Void) -> UIAlertController {
        let alertController = UIAlertController(title: WMFLocalizedString("explore-feed-preferences-turn-off-explore-tab-title", value: "Turn off the Explore tab?", comment: "Title for alert that allows users to turn off the Explore tab"), message: WMFLocalizedString("explore-feed-preferences-turn-off-explore-tab-message", value: "The Explore tab can be turned back on in Explore feed settings", comment: "Message for alert that allows users to turn off the Explore tab"), preferredStyle: .alert)
        let turnOffExplore = UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-turn-off-explore-tab-action-title", value: "Turn off Explore", comment: "Title for action that allows users to turn off the Explore tab"), style: .destructive, handler: { _ in
            turnedOff()
        })
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in
            cancelled()
        })
        alertController.addAction(turnOffExplore)
        alertController.addAction(cancel)
        return alertController
    }
}

// MARK: - UITableViewDelegate

extension ExploreFeedSettingsViewController {
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
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
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension ExploreFeedSettingsViewController {

    override func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        activeSwitch = sender
        let controlTag = sender.tag
        guard let feedContentController = feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        guard controlTag != -1 else { // main switch
            if sender.isOn {
                present(turnOnExploreAlertController(turnedOn: {
                    self.dataStore?.feedContentController.toggleAllContentGroupKinds(true, updateFeed: false)
                    UserDefaults.standard.defaultTabType = .explore
                }, cancelled: {
                    sender.setOn(false, animated: true)
                }), animated: true)
            } else {
                present(turnOffExploreAlertController(turnedOff: {
                    self.dataStore?.feedContentController.toggleAllContentGroupKinds(false, updateFeed: false)
                    UserDefaults.standard.defaultTabType = .settings
                }, cancelled: {
                    sender.setOn(true, animated: true)
                }), animated: true)
            }
            return
        }
        guard controlTag != -2 else { // global cards
            feedContentController.toggleGlobalContentGroupKinds(sender.isOn, updateFeed: false)
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
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn, updateFeed: false)
        } else {
            guard let language = languages.first(where: { $0.controlTag == controlTag }) else {
                assertionFailure("No language for given control tag")
                return
            }
            feedContentController.toggleContent(forSiteURL: language.siteURL, isOn: sender.isOn, waitForCallbackFromCoordinator: true, updateFeed: false)
        }
    }
}

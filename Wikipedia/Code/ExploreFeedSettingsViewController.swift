import WMFComponents
import WMFData
import WMFNativeLocalizations

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
            iconColor = WMFColor.gray400
            iconBackgroundColor = WMFColor.gray200
        case .onThisDay:
            title = CommonStrings.onThisDayTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-on-this-day-description", value: "Events in history on this day", comment: "Description of On this day section of Explore feed")
            iconName = "on-this-day-mini"
            iconColor = WMFColor.blue600
            iconBackgroundColor = WMFColor.blue100
        case .featuredArticle:
            title = CommonStrings.featuredArticleTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-featured-article-description", value: "Daily featured article on Wikipedia", comment: "Description of Featured article section of Explore feed")
            iconName = "featured-mini"
            iconColor = WMFColor.yellow600
            iconBackgroundColor = WMFColor.yellow600.withAlphaComponent(0.3)
        case .topRead:
            title = CommonStrings.topReadTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-top-read-description", value: "Daily most read articles", comment: "Description of Top read section of Explore feed")
            iconName = "trending-mini"
            iconColor = WMFColor.blue600
            iconBackgroundColor = WMFColor.blue100
        case .location:
            fallthrough
        case .locationPlaceholder:
            title = CommonStrings.placesTabTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-places-description", value: "Wikipedia articles near your location", comment: "Description of Places section of Explore feed")
            iconName = "nearby-mini"
            iconColor = WMFColor.green600
            iconBackgroundColor = WMFColor.green100
        case .random:
            title = CommonStrings.randomizerTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-randomizer-description", value: "Generate random articles to read", comment: "Description of Randomizer section of Explore feed")
            iconName = "random-mini"
            iconColor = WMFColor.red600
            iconBackgroundColor = WMFColor.red100
        case .dailyGame:
            title = CommonStrings.settingsGamesTitle
            singleLanguageDescription = CommonStrings.settingsGamesSubtitle
            iconName = "games-mini"
            iconColor = WMFColor.white
            iconBackgroundColor = WMFColor.yellow600
        case .pictureOfTheDay:
            title = CommonStrings.pictureOfTheDayTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-potd-description", value: "Daily featured image from Commons", comment: "Description of Picture of the day section of Explore feed")
            iconName = "potd-mini"
            iconColor = WMFColor.purple600
            iconBackgroundColor = WMFColor.purple600.withAlphaComponent(0.3)
        case .continueReading:
            title = CommonStrings.continueReadingTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-continue-reading-description", value: "Quick link back to reading an open article", comment: "Description of Continue reading section of Explore feed")
            iconName = "today-mini"
            iconColor = WMFColor.gray400
            iconBackgroundColor = WMFColor.gray200
        case .relatedPages:
            title = CommonStrings.relatedPagesTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-related-pages-description", value: "Suggestions based on reading history", comment: "Description of Related pages section of Explore feed")
            iconName = "recent-mini"
            iconColor = WMFColor.gray400
            iconBackgroundColor = WMFColor.gray200
        case .suggestedEdits:
            title = CommonStrings.suggestedEditsTitle
            singleLanguageDescription = WMFLocalizedString("explore-feed-preferences-suggested-edits-description", value: "Suggestions to add content to Wikipedia", comment: "Description of Suggested Edits section of Explore feed")
            iconName = "pencil"
            iconColor = WMFColor.blue600
            iconBackgroundColor = WMFColor.blue100
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

/// The legacy Explore feed powers the Community segment of the Home tab, so this screen is the
/// Community feed settings. The feed cannot be turned off: hiding every card just shows an empty state.
@objc(WMFExploreFeedSettingsViewController)
class ExploreFeedSettingsViewController: BaseExploreFeedSettingsViewController, WMFNavigationBarConfiguring {
    
    public var showCloseButton = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        configureNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if updateFeedBeforeViewDisappears {
            feedContentController?.updateFeedSourcesUserInitiated(true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(!preferredLanguages.isEmpty)
        displayType = preferredLanguages.count == 1 ? .singleLanguage : .multipleLanguages
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.communityFeedTitle, customView: nil, alignment: .centerCompact)
        var closeConfig: WMFLargeCloseButtonConfig? = nil
        
        if showCloseButton {
            closeConfig = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(closeButtonPressed), alignment: .trailing)
        }
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func closeButtonPressed() {
        dismiss(animated: true)
    }

    var editCount: Int {
        guard let siteURL = self.dataStore?.languageLinkController.appLanguage?.siteURL,
        let editCount = self.dataStore?.authenticationManager.permanentUser(siteURL: siteURL)?.editCount else {
            return 0
        }
        
        return Int(editCount)
    }

    // MARK: Items

    private lazy var feedCards: [FeedCard] = {
        var cards = WMFContentGroupKind.communityFeedCardKinds.map { FeedCard(contentGroupKind: $0, displayType: displayType) }

        let shouldShowSuggestedEdits = !UIAccessibility.isVoiceOverRunning && editCount >= 50
        if shouldShowSuggestedEdits {
            cards.append(FeedCard(contentGroupKind: .suggestedEdits, displayType: displayType))
        }

        return cards
    }()

    private lazy var globalCards: ExploreFeedSettingsGlobalCards = {
        return ExploreFeedSettingsGlobalCards()
    }()

    // MARK: Sections

    private lazy var customizationSection: ExploreFeedSettingsSection = {
        let headerTitle = WMFLocalizedString("new-explore-feed-preferences-customize-explore-feed", value: "Customize the Community feed", comment: "Title of the Settings section that allows users to customize the Community feed")
        let footerTitle = WMFLocalizedString("new-explore-feed-preferences-customize-explore-feed-footer-text", value: "Hiding a card type will stop this card type from appearing in the Community feed.", comment: "Text for explaining the effects of hiding feed cards")
        return ExploreFeedSettingsSection(headerTitle: headerTitle, footerTitle: footerTitle, items: feedCards)
    }()

    private lazy var languagesSection: ExploreFeedSettingsSection? = {
        guard displayType == .multipleLanguages else {
            return nil
        }
        var items: [ExploreFeedSettingsItem] = languages
        items.append(globalCards)
        return ExploreFeedSettingsSection(headerTitle: CommonStrings.languagesTitle, footerTitle: "", items: items)
    }()

    override var sections: [ExploreFeedSettingsSection] {
        var sections = [customizationSection]
        if displayType == .multipleLanguages, let languagesSection {
            sections.append(languagesSection)
        }
        return sections
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
            if contentGroupKind == .suggestedEdits {
                ImageRecommendationsFunnel.shared.logSettingsToggleSuggestedEditsCard(isOn: sender.isOn)
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

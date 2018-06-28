import UIKit

private extension WMFContentGroupKind {
    var masterSwitchTitle: String {
        switch self {
        case .news:
            return WMFLocalizedString("explore-feed-preferences-show-news-title", value: "Show In the news card", comment: "Text for the setting that allows users to toggle the visiblity of the In the news card")
        case .featuredArticle:
            return WMFLocalizedString("explore-feed-preferences-show-featured-article-title", value: "Show Featured article card", comment: "Text for the setting that allows users to toggle the visiblity of the Featured article card")
        case .topRead:
            return WMFLocalizedString("explore-feed-preferences-show-top-read-title", value: "Show Top read card", comment: "Text for the setting that allows users to toggle the visiblity of the Top read card")
        case .onThisDay:
            return WMFLocalizedString("explore-feed-preferences-show-on-this-day-title", value: "Show On this day card", comment: "Text for the setting that allows users to toggle the visiblity of the On this day card")
        case .pictureOfTheDay:
            return WMFLocalizedString("explore-feed-preferences-show-picture-of-the-day-title", value: "Show Picture of the day card", comment: "Text for the setting that allows users to toggle the visiblity of the Picture of the day card")
        case .locationPlaceholder:
            fallthrough
        case .location:
            return WMFLocalizedString("explore-feed-preferences-show-places-title", value: "Show Places card", comment: "Text for the setting that allows users to toggle the visiblity of the Places card")
        case .random:
            return WMFLocalizedString("explore-feed-preferences-show-randomizer-title", value: "Show Randomizer card", comment: "Text for the setting that allows users to toggle the visiblity of the Randomizer card")
        case .continueReading:
            return WMFLocalizedString("explore-feed-preferences-show-continue-reading-title", value: "Show Continue reading card", comment: "Text for the setting that allows users to toggle the visiblity of the Continue reading card")
        case .relatedPages:
            return WMFLocalizedString("explore-feed-preferences-show-related-pages-title", value: "Show Because you read card", comment: "Text for the setting that allows users to toggle the visiblity of the Because you read card")
        default:
            assertionFailure("\(self) is not customizable")
            return ""
        }
    }

    var togglingFeedCardFooterText: String {
        switch self {
        case .news:
            return WMFLocalizedString("explore-feed-preferences-show-news-footer-text", value: "Turning off the In the news card will turn the card off in all available languages.", comment: "Text describing the effects of turning off the In the news card")
        case .featuredArticle:
            return WMFLocalizedString("explore-feed-preferences-show-featured-article-footer-text", value: "Turning off the Featured article card will turn the card off in all available languages.", comment: "Text describing the effects of turning off the Featured article card")
        case .topRead:
            return WMFLocalizedString("explore-feed-preferences-show-top-read-footer-text", value: "Turning off the Top read card will turn the card off in all available languages.", comment: "Text describing the effects of turning off the Top read card")
        case .onThisDay:
            return WMFLocalizedString("explore-feed-preferences-show-on-this-day-footer-text", value: "Turning off the On this day card will turn the card off in all available languages.", comment: "Text describing the effects of turning off the On this day card")
        case .continueReading:
            fallthrough // TODO: Update copy
        case .relatedPages:
            fallthrough // TODO: Update copy
        case .pictureOfTheDay:
            return "Turning off this card will turn it off. 🤷🏻‍♀️" // TODO: Update copy
        case .locationPlaceholder:
            fallthrough
        case .location:
            return WMFLocalizedString("explore-feed-preferences-show-places-footer-text", value: "Turning off the Places card will turn the card off in all available languages.", comment: "Text describing the effects of turning off the Places card")
        case .random:
            return WMFLocalizedString("explore-feed-preferences-show-randomizer-footer-text", value: "Turning off the Randomizer card will turn the card off in all available languages.", comment: "Text describing the effects of turning off the Randomizer card")
        default:
            assertionFailure("\(self) is not customizable")
            return ""
        }
    }
}

class FeedCardSettingsViewController: BaseExploreFeedSettingsViewController {
    private var contentGroupKind: WMFContentGroupKind = .unknown

    func configure(with title: String, dataStore: MWKDataStore?, contentGroupKind: WMFContentGroupKind, theme: Theme) {
        self.title = title
        self.dataStore = dataStore
        self.contentGroupKind = contentGroupKind
        self.theme = theme
    }

    override func isLanguageSwitchOn(for languageLink: MWKLanguageLink) -> Bool {
        return languageLink.isInFeed(for: contentGroupKind)
    }

    private var isMasterSwitchOn: Bool {
        guard let settingsCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WMFSettingsTableViewCell else {
            return false
        }
         return settingsCell.disclosureSwitch.isOn
    }

    private lazy var masterSwitchTitle: String = {
        return contentGroupKind.masterSwitchTitle
    }()

    private lazy var togglingFeedCardFooterText: String = {
        return contentGroupKind.togglingFeedCardFooterText
    }()

    override var sections: [ExploreFeedSettingsSection] {
        let master = ExploreFeedSettingsMaster(title: masterSwitchTitle, isOn: contentGroupKind.isInFeed)
        let main = ExploreFeedSettingsSection(headerTitle: nil, footerTitle: togglingFeedCardFooterText, items: [master])
        let languageItems: [ExploreFeedSettingsItem] = contentGroupKind.isGlobal ? [ExploreFeedSettingsGlobalCards()] : self.languages
        let languagesFooterTitle = contentGroupKind.isGlobal ? "🐕🐕🐕🐕" : String.localizedStringWithFormat("%@ %@", WMFLocalizedString("explore-feed-preferences-additional-languages-footer-text", value: "Additional languages can be added in the ‘My languages’ settings page.", comment: "Text explaining how to add additional languages"), togglingFeedCardFooterText)
        let languages = ExploreFeedSettingsSection(headerTitle: CommonStrings.languagesTitle, footerTitle: languagesFooterTitle, items: languageItems)
        return [main, languages]
    }

    override func needsReloading(_ item: ExploreFeedSettingsItem) -> Bool {
        return item is ExploreFeedSettingsMaster
    }

    override var shouldReload: Bool {
        return isMasterSwitchOn != contentGroupKind.isInFeed
    }

}

// MARK: - WMFSettingsTableViewCellDelegate

extension FeedCardSettingsViewController {
    override func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        let controlTag = sender.tag
        guard let feedContentController = feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        guard controlTag != -1 else { // master switch
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn)
            return
        }
        guard controlTag != -2 else { // global cards
            feedContentController.toggleGlobalContentGroupKinds(sender.isOn)
            return
        }
        guard let language = languages.first(where: { $0.controlTag == sender.tag }) else {
            assertionFailure("No language for a given control tag")
            return
        }
        feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn, forSiteURL: language.siteURL)
    }
}

import UIKit

private extension WMFContentGroupKind {
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
            fallthrough
        case .relatedPages:
            fallthrough
        case .pictureOfTheDay:
            return WMFLocalizedString("explore-feed-preferences-global-card-footer-text", value: "This card is not language specific, turning off this card will remove it from your Explore feed.", comment: "Text describing the effects of turning off a global card")
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
        displayType = .detail(contentGroupKind)
    }
    
    // MARK: Sections

    private lazy var togglingFeedCardFooterText: String = {
        return contentGroupKind.togglingFeedCardFooterText
    }()

    private lazy var mainSection: ExploreFeedSettingsSection = {
        return ExploreFeedSettingsSection(headerTitle: nil, footerTitle: togglingFeedCardFooterText, items: [ExploreFeedSettingsPrimary(for: .singleFeedCard(contentGroupKind))])
    }()

    private lazy var languagesSection: ExploreFeedSettingsSection = {
        return ExploreFeedSettingsSection(headerTitle: CommonStrings.languagesTitle, footerTitle: String.localizedStringWithFormat("%@ %@", WMFLocalizedString("explore-feed-preferences-additional-languages-footer-text", value: "Additional languages can be added in the ‘My languages’ settings page.", comment: "Text explaining how to add additional languages"), togglingFeedCardFooterText), items: languages)
    }()

    override var sections: [ExploreFeedSettingsSection] {
        if contentGroupKind.isGlobal {
            return [mainSection]
        } else {
            return [mainSection, languagesSection]
        }
    }

}

// MARK: - WMFSettingsTableViewCellDelegate

extension FeedCardSettingsViewController {
    override func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        activeSwitch = sender
        let controlTag = sender.tag
        guard let feedContentController = feedContentController else {
            assertionFailure("feedContentController is nil")
            return
        }
        guard controlTag != -1 else { // main switch
            feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn, updateFeed: false)
            return
        }
        guard let language = languages.first(where: { $0.controlTag == sender.tag }) else {
            assertionFailure("No language for a given control tag")
            return
        }
        feedContentController.toggleContentGroup(of: contentGroupKind, isOn: sender.isOn, forSiteURL: language.siteURL, updateFeed: false)
    }
}

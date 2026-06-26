import SwiftUI
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedCommunitySettingsViewModel: ObservableObject {

    public enum Module: CaseIterable {
        case featuredArticle
        case topRead
        case inTheNews
        case onThisDay
        case pictureOfTheDay
    }

    let title = WMFLocalizedString("home-feed-modules-settings-title", value: "Modules", comment: "Navigation bar title for the Community modules settings screen.")
    let headerText = WMFLocalizedString("home-feed-modules-settings-header", value: "Turning off a module hides it from your Community feed. You can re-enable it here at any time. Some modules may not be available in your language.", comment: "Header text describing what turning Community feed modules on or off does.")
    
    private let homeDataController: WMFHomeDataController

    @Published public var featuredArticleIsOn: Bool
    @Published public var topReadIsOn: Bool
    @Published public var inTheNewsIsOn: Bool
    @Published public var onThisDayIsOn: Bool
    @Published public var pictureOfTheDayIsOn: Bool

    public var onToggleModule: ((Module, Bool) -> Void)?

    public private(set) var sections: [SettingsSection] = []

    public init(homeDataController: WMFHomeDataController = .shared) {
        self.homeDataController = homeDataController
        self.featuredArticleIsOn = homeDataController.communityFeaturedArticleIsOn()
        self.topReadIsOn = homeDataController.communityTopReadIsOn()
        self.inTheNewsIsOn = homeDataController.communityInTheNewsIsOn()
        self.onThisDayIsOn = homeDataController.communityOnThisDayIsOn()
        self.pictureOfTheDayIsOn = homeDataController.communityPictureOfTheDayIsOn()
        self.onToggleModule =  { [weak self] module, isOn in
            guard let self else { return }
            switch module {
            case .featuredArticle: self.homeDataController.setCommunityFeaturedArticleIsOn(isOn)
            case .topRead: self.homeDataController.setCommunityTopReadIsOn(isOn)
            case .inTheNews: self.homeDataController.setCommunityInTheNewsIsOn(isOn)
            case .onThisDay: self.homeDataController.setCommunityOnThisDayIsOn(isOn)
            case .pictureOfTheDay: self.homeDataController.setCommunityPictureOfTheDayIsOn(isOn)
            }
        }
        self.sections = buildSections()
    }

    private func buildSections() -> [SettingsSection] {
        let featuredArticle = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-modules-featured-article-title", value: "Featured article", comment: "Title for the Featured article module toggle."),
            subtitle: WMFLocalizedString("home-feed-modules-featured-article-subtitle", value: "Featured articles are some of the highest-quality articles on Wikipedia, selected daily by editors", comment: "Subtitle describing the Featured article module."),
            accessory: .toggle(binding(for: .featuredArticle)),
            action: nil
        )

        let topRead = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-modules-top-read-title", value: "Top read", comment: "Title for the Top read module toggle."),
            subtitle: WMFLocalizedString("home-feed-modules-top-read-subtitle", value: "What is trending today on Wikipedia", comment: "Subtitle describing the Top read module."),
            accessory: .toggle(binding(for: .topRead)),
            action: nil
        )

        let inTheNews = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-modules-in-the-news-title", value: "In the news", comment: "Title for the In the news module toggle."),
            subtitle: WMFLocalizedString("home-feed-modules-in-the-news-subtitle", value: "Articles that have been substantially updated to reflect recent or current events of wide interest", comment: "Subtitle describing the In the news module."),
            accessory: .toggle(binding(for: .inTheNews)),
            action: nil
        )

        let onThisDay = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-modules-on-this-day-title", value: "On this day", comment: "Title for the On this day module toggle."),
            subtitle: WMFLocalizedString("home-feed-modules-on-this-day-subtitle", value: "Discover historical events from this day", comment: "Subtitle describing the On this day module."),
            accessory: .toggle(binding(for: .onThisDay)),
            action: nil
        )

        let pictureOfTheDay = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-modules-picture-of-the-day-title", value: "Picture of the day", comment: "Title for the Picture of the day module toggle."),
            subtitle: WMFLocalizedString("home-feed-modules-picture-of-the-day-subtitle", value: "Daily images on Wikimedia Commons, selected by volunteer contributors", comment: "Subtitle describing the Picture of the day module."),
            accessory: .toggle(binding(for: .pictureOfTheDay)),
            action: nil
        )

        return [
            SettingsSection(header: headerText, footer: nil, items: [featuredArticle, topRead, inTheNews, onThisDay, pictureOfTheDay])
        ]
    }

    private func binding(for module: Module) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                guard let self else { return false }
                switch module {
                case .featuredArticle: return self.featuredArticleIsOn
                case .topRead: return self.topReadIsOn
                case .inTheNews: return self.inTheNewsIsOn
                case .onThisDay: return self.onThisDayIsOn
                case .pictureOfTheDay: return self.pictureOfTheDayIsOn
                }
            },
            set: { [weak self] newValue in
                guard let self else { return }
                switch module {
                case .featuredArticle: self.featuredArticleIsOn = newValue
                case .topRead: self.topReadIsOn = newValue
                case .inTheNews: self.inTheNewsIsOn = newValue
                case .onThisDay: self.onThisDayIsOn = newValue
                case .pictureOfTheDay: self.pictureOfTheDayIsOn = newValue
                }
                self.onToggleModule?(module, newValue)
            }
        )
    }
}

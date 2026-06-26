import SwiftUI
import WMFNativeLocalizations

@MainActor
public final class WMFHomeFeedWhatsDrivingSettingsViewModel: ObservableObject {

    let title = WMFLocalizedString("home-feed-whats-driving-settings-title", value: "What's driving your feed", comment: "Navigation bar title for the What's driving your feed settings screen.")
    let headerText = WMFLocalizedString("home-feed-whats-driving-settings-header", value: "These topics and articles shape what appears in your \"For You\" feed. Remove any you no longer want or add new interests.", comment: "Header text describing what the topics and articles on the What's driving your feed screen control.")

    public var didTapYourInterests: (() -> Void)?
    public var didTapReadingHistory: (() -> Void)?
    public var didTapLanguages: (() -> Void)?

    public private(set) var sections: [SettingsSection] = []

    public init(didTapYourInterests: (() -> Void)? = nil, didTapReadingHistory: (() -> Void)? = nil, didTapLanguages: (() -> Void)? = nil) {
        self.didTapYourInterests = didTapYourInterests
        self.didTapReadingHistory = didTapReadingHistory
        self.didTapLanguages = didTapLanguages
        self.sections = buildSections()
    }

    private func buildSections() -> [SettingsSection] {
        let yourInterests = SettingsItem(
            image: WMFSFSymbolIcon.for(symbol: .sliderHorizontal3),
            color: WMFColor.blue300,
            title: WMFLocalizedString("home-feed-whats-driving-your-interests-title", value: "Your interests", comment: "Title for the Your interests row on the What's driving your feed screen."),
            subtitle: WMFLocalizedString("home-feed-whats-driving-your-interests-subtitle", value: "Edit your topics of interest", comment: "Subtitle for the Your interests row."),
            accessory: .chevron(label: nil),
            action: didTapYourInterests
        )

        let readingHistory = SettingsItem(
            image: WMFSFSymbolIcon.for(symbol: .clockArrowCounterclockwise),
            color: WMFColor.purple600,
            title: WMFLocalizedString("home-feed-whats-driving-reading-history-title", value: "Reading history", comment: "Title for the Reading history row on the What's driving your feed screen."),
            subtitle: WMFLocalizedString("home-feed-whats-driving-reading-history-subtitle", value: "Browse your recently read articles", comment: "Subtitle for the Reading history row."),
            accessory: .chevron(label: nil),
            action: didTapReadingHistory
        )

        let languages = SettingsItem(
            image: WMFIcon.language,
            color: WMFColor.green600,
            title: WMFLocalizedString("home-feed-whats-driving-languages-title", value: "Languages", comment: "Title for the Languages row on the What's driving your feed screen."),
            subtitle: WMFLocalizedString("home-feed-whats-driving-languages-subtitle", value: "Edit your preferred languages", comment: "Subtitle for the Languages row."),
            accessory: .chevron(label: nil),
            action: didTapLanguages
        )

        return [
            SettingsSection(header: headerText, footer: nil, items: [yourInterests, readingHistory, languages])
        ]
    }
}

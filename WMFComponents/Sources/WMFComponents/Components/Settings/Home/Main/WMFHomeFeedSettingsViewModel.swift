import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFHomeFeedSettingsViewModel: ObservableObject {

    let title = WMFLocalizedString("home-feed-settings-title", value: "Customize the home feed", comment: "Navigation bar title for the Home feed customization settings screen.")

    let sections: [SettingsSection]

    public init(showCommunitySettings: Bool = WMFDeveloperSettingsDataController.shared.enableHomePhase2, didTapCommunityModules: (() -> Void)? = nil, didTapForYouModules: (() -> Void)? = nil, didTapForYouWhatsDriving: (() -> Void)? = nil) {
        let modulesTitle = WMFLocalizedString("home-feed-settings-modules-title", value: "Modules", comment: "Title for the row that lets users turn feed modules on or off in Home feed settings.")
        let communityModulesSubtitle = WMFLocalizedString("home-feed-settings-community-modules-subtitle", value: "Turn on or off 'Community' modules", comment: "Subtitle for the Modules row describing that it toggles Community modules on or off.")
        let forYouModulesSubtitle = WMFLocalizedString("home-feed-settings-for-you-modules-subtitle", value: "Turn on or off 'For You' modules", comment: "Subtitle for the Modules row describing that it toggles For You modules on or off.")
        let whatsDrivingTitle = WMFLocalizedString("home-feed-settings-whats-driving-title", value: "What's Driving your feed", comment: "Title for the row that shows what is driving the user's feed in Home feed settings.")
        let whatsDrivingSubtitle = WMFLocalizedString("home-feed-settings-whats-driving-subtitle", value: "Topics and articles shaping your content", comment: "Subtitle for the row describing the topics and articles that shape the user's feed.")

        let communityHeader = WMFLocalizedString("home-feed-settings-community-section-title", value: "Community", comment: "Section header for Community settings in Home feed settings.")
        let forYouHeader = WMFLocalizedString("home-feed-settings-for-you-section-title", value: "For you", comment: "Section header for For You settings in Home feed settings.")

        var sections: [SettingsSection] = []

        // The reworked community feed ships with home phase 2. Until then the Community segment is
        // powered by the legacy Explore feed, which has its own settings entry in the main Settings screen.
        if showCommunitySettings {
            sections.append(SettingsSection(header: communityHeader, footer: nil, items: [
                SettingsItem(image: nil, color: nil, title: modulesTitle, subtitle: communityModulesSubtitle, accessory: .chevron(label: nil), action: didTapCommunityModules)
            ]))
        }

        sections.append(SettingsSection(header: forYouHeader, footer: nil, items: [
            SettingsItem(image: nil, color: nil, title: modulesTitle, subtitle: forYouModulesSubtitle, accessory: .chevron(label: nil), action: didTapForYouModules),
            SettingsItem(image: nil, color: nil, title: whatsDrivingTitle, subtitle: whatsDrivingSubtitle, accessory: .chevron(label: nil), action: didTapForYouWhatsDriving)
        ]))

        self.sections = sections
    }
}

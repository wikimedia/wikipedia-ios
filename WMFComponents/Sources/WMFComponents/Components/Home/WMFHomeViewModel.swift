import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

extension WMFLanguage: Identifiable {
    public var id: String { [languageCode, languageVariantCode].compactMap { $0 }.joined(separator: "-") }
}

@MainActor
public final class WMFHomeViewModel: ObservableObject {

    public enum Tab: Int, CaseIterable {
        case forYou
        case community
    }

    let forYouTabTitle = WMFLocalizedString("home-for-you-tab-title", value: "For You", comment: "Title for the For You segment within the Home tab.")
    let communityTabTitle = WMFLocalizedString("home-community-tab-title", value: "Community", comment: "Title for the Community segment within the Home tab.")
    let editLanguagesTitle = WMFLocalizedString("home-edit-languages-title", value: "Add or edit languages", comment: "Title for the option at the bottom of the Home language menu that opens the languages settings screen.")

    @Published public var selectedTab: Tab = .community
    @Published public var languages: [WMFLanguage]
    @Published public var selectedLanguage: WMFLanguage?

    public var didSelectLanguage: ((WMFLanguage) -> Void)?
    public var didTapEditLanguages: (() -> Void)?

    // TODO: Temporary mock button for testing the "What's driving your feed" deep-link. Remove once the real feed entry point exists.
    let whatsDrivingTestButtonTitle = "settings test button"
    public var didTapWhatsDrivingTestButton: (() -> Void)?

    public init(languages: [WMFLanguage] = [], selectedLanguage: WMFLanguage? = nil, didSelectLanguage: ((WMFLanguage) -> Void)? = nil, didTapEditLanguages: (() -> Void)? = nil, didTapWhatsDrivingTestButton: (() -> Void)? = nil) {
        self.languages = languages
        self.selectedLanguage = selectedLanguage
        self.didSelectLanguage = didSelectLanguage
        self.didTapEditLanguages = didTapEditLanguages
        self.didTapWhatsDrivingTestButton = didTapWhatsDrivingTestButton
    }

    /// The short code shown on the language menu button (e.g. "EN").
    var languageButtonTitle: String {
        selectedLanguage?.languageCode.uppercased() ?? ""
    }
}

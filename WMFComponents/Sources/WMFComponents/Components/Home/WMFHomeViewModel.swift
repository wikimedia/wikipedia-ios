import Foundation
import SwiftUI
import WMFNativeLocalizations

@MainActor
public final class WMFHomeViewModel: ObservableObject {

    public struct Language: Identifiable, Equatable {
        public let code: String
        public let localizedName: String
        public var id: String { code }

        public init(code: String, localizedName: String) {
            self.code = code
            self.localizedName = localizedName
        }
    }

    public enum Tab: Int, CaseIterable {
        case forYou
        case community
    }

    let forYouTabTitle = WMFLocalizedString("home-for-you-tab-title", value: "For You", comment: "Title for the For You segment within the Home tab.")
    let communityTabTitle = WMFLocalizedString("home-community-tab-title", value: "Community", comment: "Title for the Community segment within the Home tab.")
    let editLanguagesTitle = WMFLocalizedString("home-edit-languages-title", value: "Add or edit languages", comment: "Title for the option at the bottom of the Home language menu that opens the languages settings screen.")

    @Published public var selectedTab: Tab = .community
    @Published public var languages: [Language]
    @Published public var selectedLanguageCode: String

    public var didSelectLanguage: ((String) -> Void)?
    public var didTapEditLanguages: (() -> Void)?

    // TODO: Temporary mock button for testing the "What's driving your feed" deep-link. Remove once the real feed entry point exists.
    let whatsDrivingTestButtonTitle = "settings test button"
    public var didTapWhatsDrivingTestButton: (() -> Void)?

    public init(languages: [Language] = [], selectedLanguageCode: String = "", didSelectLanguage: ((String) -> Void)? = nil, didTapEditLanguages: (() -> Void)? = nil, didTapWhatsDrivingTestButton: (() -> Void)? = nil) {
        self.languages = languages
        self.selectedLanguageCode = selectedLanguageCode
        self.didSelectLanguage = didSelectLanguage
        self.didTapEditLanguages = didTapEditLanguages
        self.didTapWhatsDrivingTestButton = didTapWhatsDrivingTestButton
    }

    /// The short code shown on the language menu button (e.g. "EN").
    var languageButtonTitle: String {
        selectedLanguageCode.uppercased()
    }
}

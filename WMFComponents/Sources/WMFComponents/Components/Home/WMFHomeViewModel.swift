import Foundation
import SwiftUI

@MainActor
public final class WMFHomeViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let forYouTabTitle: String
        public let communityTabTitle: String
        public let editLanguagesTitle: String

        public init(title: String, forYouTabTitle: String, communityTabTitle: String, editLanguagesTitle: String) {
            self.title = title
            self.forYouTabTitle = forYouTabTitle
            self.communityTabTitle = communityTabTitle
            self.editLanguagesTitle = editLanguagesTitle
        }
    }

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

    let localizedStrings: LocalizedStrings

    @Published public var selectedTab: Tab = .forYou
    @Published public var languages: [Language]
    @Published public var selectedLanguageCode: String

    public var didSelectLanguage: ((String) -> Void)?
    public var didTapEditLanguages: (() -> Void)?

    public init(localizedStrings: LocalizedStrings, languages: [Language] = [], selectedLanguageCode: String = "", didSelectLanguage: ((String) -> Void)? = nil, didTapEditLanguages: (() -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.languages = languages
        self.selectedLanguageCode = selectedLanguageCode
        self.didSelectLanguage = didSelectLanguage
        self.didTapEditLanguages = didTapEditLanguages
    }

    /// The short code shown on the language menu button (e.g. "EN").
    var languageButtonTitle: String {
        selectedLanguageCode.uppercased()
    }
}

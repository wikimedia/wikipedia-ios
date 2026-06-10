import Foundation
import SwiftUI

@MainActor
public final class WMFHomeViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let forYouTabTitle: String
        public let communityTabTitle: String

        public init(title: String, forYouTabTitle: String, communityTabTitle: String) {
            self.title = title
            self.forYouTabTitle = forYouTabTitle
            self.communityTabTitle = communityTabTitle
        }
    }

    public enum Tab: Int, CaseIterable {
        case forYou
        case community
    }

    let localizedStrings: LocalizedStrings

    @Published public var selectedTab: Tab = .forYou
    @Published public var currentLanguageCode: String

    /// Called when the user taps the language picker. Wired up app-side by the coordinator.
    public var didTapLanguagePicker: (() -> Void)?

    public init(localizedStrings: LocalizedStrings, currentLanguageCode: String, didTapLanguagePicker: (() -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.currentLanguageCode = currentLanguageCode
        self.didTapLanguagePicker = didTapLanguagePicker
    }
}

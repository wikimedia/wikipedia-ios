import Foundation

public final class WMFReadingChallengeWidgetViewModel: ObservableObject {

    // MARK: - Localized Strings

    public struct LocalizedStrings {
        public let title: String
        public let subtitle: String

        public init(title: String, subtitle: String) {
            self.title = title
            self.subtitle = subtitle
        }
    }

    // MARK: - Properties

    public let localizedStrings: LocalizedStrings

    // MARK: - Init

    public init(localizedStrings: LocalizedStrings) {
        self.localizedStrings = localizedStrings
    }
}

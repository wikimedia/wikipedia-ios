import Foundation
import SwiftUI

public final class WMFReadingChallengeWidgetViewModel: ObservableObject {

    // MARK: - Localized Strings

    public struct LocalizedStrings {
        public let title: String

        public init(title: String) {
            self.title = title
        }
    }

    // MARK: - Display Set

    public struct DisplaySet {
        public let color: Color
        public let color2: Color
        public let image: String
        public let title: String
        public let subtitle: String?
        public let button1Title: String?
        public let button2Title: String?
        public let button1URL: URL?
        public let button2URL: URL?

        public init(
            color: Color,
            color2: Color,
            image: String,
            title: String,
            subtitle: String? = nil,
            button1Title: String? = nil,
            button2Title: String? = nil,
            button1URL: URL? = nil,
            button2URL: URL? = nil
        ) {
            self.color = color
            self.color2 = color2
            self.image = image
            self.title = title
            self.subtitle = subtitle
            self.button1Title = button1Title
            self.button2Title = button2Title
            self.button1URL = button1URL
            self.button2URL = button2URL
        }
    }

    // MARK: - Properties

    public let localizedStrings: LocalizedStrings
    public let displaySet: DisplaySet
    @Published public var state: ReadingChallengeState

    // MARK: - Init

    public init(localizedStrings: LocalizedStrings, displaySet: DisplaySet, state: ReadingChallengeState = .streakOngoingRead) {
        self.localizedStrings = localizedStrings
        self.displaySet = displaySet
        self.state = state
    }
}

public enum ReadingChallengeState {
    case notEnrolled
    case streakOngoingRead
    case streakOngoingNotYetRead
    case challengeConcludedCompletedSuccessfully
    case challengeConcludedIncomplete
    case challengeConcludedNoStreak
}

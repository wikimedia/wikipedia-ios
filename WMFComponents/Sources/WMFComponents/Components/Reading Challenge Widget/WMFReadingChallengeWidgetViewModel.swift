import Foundation
import SwiftUI

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
    @Published public var state: ReadingChallengeState

    // MARK: - Init

    public init(localizedStrings: LocalizedStrings, state: ReadingChallengeState = .streakOngoingRead) {
        self.localizedStrings = localizedStrings
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
    
    public struct DisplaySet {
        let color: Color
        let color2: Color
        let image: String
        let text: String
    }
    
    public var displaySets: [DisplaySet] {
        switch self {
        default:
            return [
                DisplaySet(color: .blue, color2: .blue, image: "globe1", text: "Hello")
            ]
        }
    }
}

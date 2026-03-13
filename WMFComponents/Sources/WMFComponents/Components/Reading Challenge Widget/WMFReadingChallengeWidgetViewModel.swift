import Foundation
import SwiftUI
import WMFData

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
        public let button1Icon: String?
        public let button2Icon: String?
        public let buttonBackgroundColor: Color?
        public let smallShowButtons: Bool

        public init(
            color: Color,
            color2: Color,
            image: String,
            title: String,
            subtitle: String? = nil,
            button1Title: String? = nil,
            button2Title: String? = nil,
            button1URL: URL? = nil,
            button2URL: URL? = nil,
            button1Icon: String? = nil,
            button2Icon: String? = nil,
            buttonBackgroundColor: Color? = nil,
            smallShowButtons: Bool = false
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
            self.button1Icon = button1Icon
            self.button2Icon = button2Icon
            self.buttonBackgroundColor = buttonBackgroundColor
            self.smallShowButtons = smallShowButtons
        }
    }

    // MARK: - Properties

    public let localizedStrings: LocalizedStrings
    public let displaySet: DisplaySet
    @Published public var state: ReadingChallengeState

    // MARK: - Init

    public init(
        localizedStrings: LocalizedStrings,
        displaySet: DisplaySet,
        state: ReadingChallengeState = .notEnrolled
    ) {
        self.localizedStrings = localizedStrings
        self.displaySet = displaySet
        self.state = state
    }
}

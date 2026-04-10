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
        public let color3: Color?
        public let image: String
        public let title: String
        public let icon: UIImage?
        public let subtitle: String?
        public let button1Title: String?
        public let button2Title: String?
        public let button1URL: URL?
        public let button2URL: URL?
        public let button1Icon: UIImage?
        public let button2Icon: UIImage?
        public let buttonBackgroundColor: Color?
        public let smallShowButtons: Bool
        public let smallerIcon1: UIImage?

        public init(
            color: Color,
            color2: Color,
            color3: Color? = nil,
            image: String,
            title: String,
            subtitle: String? = nil,
            button1Title: String? = nil,
            button2Title: String? = nil,
            button1URL: URL? = nil,
            button2URL: URL? = nil,
            button1Icon: UIImage? = nil,
            button2Icon: UIImage? = nil,
            buttonBackgroundColor: Color? = nil,
            smallShowButtons: Bool = false,
            icon: UIImage? = nil,
            icon2: UIImage? = nil
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
            self.icon = icon
            self.color3 = color3
            self.smallerIcon1 = icon2
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

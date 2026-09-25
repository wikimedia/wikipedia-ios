import UIKit

public struct WMFYearInReviewSlideViewModel: Identifiable {

    public struct LocalizedStrings {
        public var accessibilityLabel: String?

        public init(accessibilityLabel: String? = nil) {
            self.accessibilityLabel = accessibilityLabel
        }
    }

    /// Which color the app draws its own controls in above the animation.

    public enum ContentStyle {
        /// Light controls, for dark artwork.
        case light
        /// Dark controls, for light artwork.
        case dark
    }

    public let id: String
    public let loggingID: String
    public let animation: WMFRiveAnimation?
    public let text: [WMFRiveText: String]
    public let numbers: [WMFRiveNumber: Double]
    public let localizedStrings: LocalizedStrings
    public let showsShareButton: Bool
    public let showsDonateButton: Bool
    public let contentStyle: ContentStyle

    public init(
        id: String,
        loggingID: String,
        animation: WMFRiveAnimation? = nil,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        localizedStrings: LocalizedStrings = LocalizedStrings(),
        showsShareButton: Bool = true,
        showsDonateButton: Bool = true,
        contentStyle: ContentStyle = .light
    ) {
        self.id = id
        self.loggingID = loggingID
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.localizedStrings = localizedStrings
        self.showsShareButton = showsShareButton
        self.showsDonateButton = showsDonateButton
        self.contentStyle = contentStyle
    }

    public var prefersLightContent: Bool {
        contentStyle == .light
    }

    public var contentColor: UIColor {
        prefersLightContent ? WMFColor.white : WMFColor.gray700
    }
}

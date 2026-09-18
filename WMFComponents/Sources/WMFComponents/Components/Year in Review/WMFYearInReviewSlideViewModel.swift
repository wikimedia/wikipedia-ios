import UIKit

public struct WMFYearInReviewSlideViewModel: Identifiable {

    public struct LocalizedStrings {
        public var accessibilityLabel: String?

        public init(accessibilityLabel: String? = nil) {
            self.accessibilityLabel = accessibilityLabel
        }
    }

    public enum ContentStyle {
        case automatic
        case light
        case dark
    }

    public let id: String
    public let loggingID: String
    public let animation: WMFRiveAnimation?
    public let text: [WMFRiveText: String]
    public let numbers: [WMFRiveNumber: Double]
    public let backgroundColor: UIColor
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
        backgroundColor: UIColor,
        localizedStrings: LocalizedStrings = LocalizedStrings(),
        showsShareButton: Bool = true,
        showsDonateButton: Bool = true,
        contentStyle: ContentStyle = .automatic
    ) {
        self.id = id
        self.loggingID = loggingID
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.backgroundColor = backgroundColor
        self.localizedStrings = localizedStrings
        self.showsShareButton = showsShareButton
        self.showsDonateButton = showsDonateButton
        self.contentStyle = contentStyle
    }

    public var prefersLightContent: Bool {
        switch contentStyle {
        case .light:
            return true
        case .dark:
            return false
        case .automatic:
            return backgroundColor.wmfIsDark
        }
    }

    public var contentColor: UIColor {
        prefersLightContent ? WMFColor.white : WMFColor.gray700
    }
}

extension UIColor {
    var wmfIsDark: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance < 0.5
    }
}

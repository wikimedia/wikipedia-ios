import UIKit

/// The content of one toast.
public struct WMFToastConfig {

    /// The way the card shows the icon.
    public enum IconStyle {
        /// A template image. The card tints the image with the secondary text color.
        case symbol
        /// A photo. The card clips the image to a rounded rectangle.
        case thumbnail
    }

    let title: String
    let subtitle: String?
    let icon: UIImage?
    let iconStyle: IconStyle
    /// The time in seconds before the toast closes. Set nil to keep the toast open.
    let duration: TimeInterval?
    let buttonTitle: String?
    /// The card calls this closure when the user taps the card.
    let tapAction: (() -> Void)?
    /// The card calls this closure when the user taps the button. Then the toast closes.
    let buttonAction: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        icon: UIImage? = nil,
        iconStyle: IconStyle = .symbol,
        duration: TimeInterval? = 2,
        buttonTitle: String? = nil,
        tapAction: (() -> Void)? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconStyle = iconStyle
        self.duration = duration
        self.buttonTitle = buttonTitle
        self.tapAction = tapAction
        self.buttonAction = buttonAction
    }
}

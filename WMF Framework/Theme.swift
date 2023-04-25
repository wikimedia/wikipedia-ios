import Foundation
import SystemConfiguration
import Components

public extension UIColor {
    @objc(initWithHexInteger:alpha:)
    convenience init(_ hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    @objc(initWithHexInteger:)
    convenience init(_ hex: Int) {
        self.init(hex, alpha: 1)
    }
    
    @objc class func wmf_colorWithHex(_ hex: Int) -> UIColor {
        return UIColor(hex)
    }
    
    // `initWithHexString:alpha:` should almost never be used. `initWithHexInteger:alpha:` is preferred.
    @objc(initWithHexString:alpha:)
    convenience init(_ hexString: String, alpha: CGFloat = 1.0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6,
              let int = Scanner(string: hex).scanInt32(representation: .hexadecimal),
              int != UINT32_MAX else {
            assertionFailure("Unexpected issue scanning hex string: \(hexString)")
            self.init(white: 0, alpha: alpha)
            return
        }
        self.init(Int(int), alpha: alpha)
    }
    
    // Make colors accessible to @objc
    @objc static var wmf_blue_700: UIColor {
        return .blue700
    }

    @objc static var wmf_blue_300: UIColor {
        return .blue300
    }

    @objc static var wmf_blue_600: UIColor {
        return .blue600
    }

    @objc static var wmf_yellow_600: UIColor {
        return .yellow600
    }
    @objc static var wmf_red_600: UIColor {
        return .red600
    }

    @objc static var wmf_gray_400: UIColor {
        return .gray400
    }

    @objc static var wmf_green_600: UIColor {
        return .green600
    }

    @objc static var wmf_purple: UIColor {
        return .purple600
    }

    @objc static var wmf_orange: UIColor {
        return .orange600
    }

    @objc func wmf_hexStringIncludingAlpha(_ includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        var hexString = String(format: "%02X%02X%02X", Int(255.0 * r), Int(255.0 * g), Int(255.0 * b))
        if includeAlpha {
            hexString = hexString.appendingFormat("%02X", Int(255.0 * a))
        }
        return hexString
    }
    
    @objc var wmf_hexString: String {
        return wmf_hexStringIncludingAlpha(false)
    }
}

@objc(WMFColors)
public class Colors: NSObject {
    fileprivate static let light = Colors(
        identifier: .light)
    
    fileprivate static let sepia = Colors(identifier: .sepia)

    fileprivate static let dark = Colors(identifier: .dark)

    fileprivate static let black = Colors(identifier: .black)
    
    fileprivate static let widgetLight = Colors(identifier: .widgetLight)

    fileprivate static let widgetDark = Colors(identifier: .widgetDark)

    public let identifier: Identifier

    @objc public var baseBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray200
        case .sepia:
            return .beige400
        case .dark, .black, .widgetDark:
            return .gray800
        }
    }

    @objc public var midBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .beige300
        case .dark, .black, .widgetDark:
            return .gray700
        }
    }

    @objc public var subCellBackground: UIColor {
        switch identifier {
        case .light:
            return .white
        case .sepia:
            return .beige300
        case .dark, .black:
            return .gray700
        case .widgetLight, .widgetDark:
            return .clear
        }
    }

    @objc public var paperBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .white
        case .sepia:
            return .beige100
        case .dark:
            return .gray675
        case .black, .widgetDark:
            return .black
        }
    }

    @objc public var popoverBackground: UIColor {
        switch identifier {
        case .light, .sepia:
            return .white
        case .dark:
            return .gray800
        case .black:
            return .gray700
        case .widgetLight, .widgetDark:
            return .clear
        }
    }

    @objc public var chromeBackground: UIColor {
        switch identifier {
        case .light:
            return .white
        case .sepia:
            return .beige100
        case .dark:
            return .gray700
        case .black:
            return .gray700
        case .widgetLight, .widgetDark:
            return .clear
        }
    }

    @objc public var chromeShadow: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray400
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray650
        case .black:
            return .gray675
        }
    }

    @objc public var overlayBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .black.withAlphaComponent(0.5)
        case .sepia:
            return .taupe600.withAlphaComponent(0.6)
        default:
            return .black.withAlphaComponent(0.75)
        }
    }

    @objc public var batchSelectionBackground: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .blue100
        case .dark, .black, .widgetDark:
            return .blue700

        }
    }

    @objc public var referenceHighlightBackground: UIColor {
        switch identifier {
        case .light, .sepia, .dark, .widgetLight:
            return .clear
        case .black, .widgetDark:
            return .white.withAlphaComponent(0.2)
        }
    }

    @objc public var hintBackground: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .blue100
        case .dark, .widgetDark:
            return .gray800
        case .black:
            return .gray650
        }
    }

    @objc public var hintWarningText: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .gray700
        case .dark, .black, .widgetDark:
            return .yellow600
        }
    }

    @objc public var hintWarningBackground: UIColor {
        switch identifier {
        case .light, .sepia:
            return .orange600
        case .dark, .black:
            return  .gray700
        default:
            return .clear
        }
    }

    @objc public var animationBackground: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .gray150
        case .dark, .black, .widgetDark:
            return .gray700
        }
    }
    
    @objc public var overlayText: UIColor {
        return .gray600
    }
    
    @objc public var primaryText: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .gray700
        case .dark, .black, .widgetDark:
            return .gray100
        }
    }

    @objc public var secondaryText: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray500
        case .sepia:
            return .taupe600
        default:
            return .gray300
        }
    }

    @objc public var tertiaryText: UIColor {
        switch identifier {
        case .light:
            return .gray500
        case .sepia:
            return .taupe600
        default:
            return .gray300

        }
    }

    @objc public var disabledText: UIColor {
        switch identifier {
        case .light:
            return .gray500
        case .sepia:
            return .taupe600
        default:
            return .gray300
        }
    }

    @objc public var disabledLink: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray600
        case .sepia:
            return .gray500
        case .dark, .black, .widgetDark:
            return .gray400
        }
    }
    
    @objc public var chromeText: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .gray700
        case .dark, .black, .widgetDark:
            return .gray100
        }
    }
    
    @objc public var link: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .blue600
        case .dark, .black, .widgetDark:
            return .blue300
        }
    }

    @objc public var accent: UIColor {
        switch identifier {
        default:
            return .green600
        }
    }

    @objc public var secondaryAction: UIColor {
        return .blue700
    }

    @objc public var destructive: UIColor {
        switch identifier {
        case .sepia:
            return .red700
        default:
            return .red600
        }
    }
    @objc public var warning: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .orange600
        case .dark, .black, .widgetDark:
            return .yellow600
        }
    }
    @objc public var error: UIColor {
        switch identifier {
        case .sepia:
            return .red700
        default:
            return .red600
        }
    }
    @objc public var unselected: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray400
        case .sepia:
            return .taupe600
        case .dark, .black, .widgetDark:
            return .gray300
        }
    }
    
    @objc public var border: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray400
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray650
        case .black:
            return .gray675
        }
    }

    @objc public var shadow: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray200
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray800
        case .black:
            return .gray700
        }
    }

    public var cardBackground: UIColor {
        switch identifier {
        case .light:
            return .white
        case .sepia:
            return .beige300
        case .dark, .black:
            return .gray700
        case .widgetLight, .widgetDark:
            return .clear
        }
    }

    public var selectedCardBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .beige400
        case .dark, .widgetDark:
            return .gray700
        case .black:
            return .gray675
        }
    }
    
    @objc public var cardBorder: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray650
        case .black:
            return .gray675
        }
    }

    @objc public var midCardBorder: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray200
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray650
        case .black:
            return .gray675
        }
    }

    @objc public var cardShadow: UIColor {
        switch identifier {
        case .light:
            return .gray700
        default:
            return .clear
        }
    }

    @objc public var cardButtonBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .beige300
        case .dark, .black, .widgetDark:
            return .gray650
        }
    }

    @objc public var cardButtonSelectedBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray650
        case .black:
            return .gray675
        }
    }
    
    @objc public var icon: UIColor? {
        switch identifier {
        case .sepia:
            return .taupe600
        case .dark, .black:
            return .gray300
        default:
            return nil
        }
    }

    @objc public var iconBackground: UIColor? {
        switch identifier {
        case .sepia:
            return .beige400
        case .dark, .black:
            return .gray675
        default:
            return nil
        }
    }
    
    @objc public var searchFieldBackground: UIColor {
        return .darkSearchFieldBackground
    }

    @objc public var keyboardBarSearchFieldBackground: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .gray200
        case .dark, .black, .widgetDark:
            return .gray650
        }
    }
    
    @objc public var rankGradientStart: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .blue600
        case .dark, .black, .widgetDark:
            return .blue300
        }
    }

    @objc public var rankGradientEnd: UIColor {
        return .green600
    }

    @objc public var rankGradient: Gradient {
        return Gradient(startColor: rankGradientStart, endColor: rankGradientEnd)
    }
    
    @objc public var blurEffectStyle: UIBlurEffect.Style {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .extraLight
        case .dark, .black, .widgetDark:
            return .dark
        }
    }

    @objc public var blurEffectBackground: UIColor {
        switch identifier {
        case .black, .dark, .widgetDark:
            return .gray300.withAlphaComponent(0.55)
        default:
            return .clear
        }
    }
    
    @objc public var tagText: UIColor {
        switch identifier {
        case .light:
            return .blue600
        default:
            return .white
        }
    }

    @objc public var tagBackground: UIColor {
        switch identifier {
        case .light:
            return .blue600.withAlphaComponent(0.1)
        default:
            return .blue300

        }
    }

    @objc public var tagSelectedBackground: UIColor {
        switch identifier {
        case .light:
            return .blue600.withAlphaComponent(0.25)
        default:
            return .blue600

        }
    }
    
    @objc public var  distanceBorder: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray400
        case .sepia:
            return .taupe600
        case .dark, .black, .widgetDark:
            return .gray300
        }
    }

    @objc public var descriptionBackground: UIColor {
        switch identifier {
        case .light:
            return .yellow600
        case .sepia, .widgetLight:
            return .orange600
        case .dark, .black, .widgetDark:
            return .blue300
        }
    }

    @objc public var descriptionWarning: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .orange600
        case .dark, .black, .widgetDark:
            return .yellow600
        }
    }
    
    @objc public var pageIndicator: UIColor {
        return .blue100
    }

    @objc public var pageIndicatorCurrent: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .blue600
        case .dark, .black, .widgetDark:
            return .blue300
        }
    }
    
    @objc public var unreadIndicator: UIColor {
        return .green600
    }
    
    @objc public var refreshControlTint: UIColor {
        return secondaryText
    }
    
    @objc public var inputAccessoryBackground: UIColor {
        switch identifier {
        case .light:
            return .white
        case .sepia:
            return .beige300
        case .dark, .black:
            return .gray700
        case .widgetLight, .widgetDark:
            return .clear
        }
    }

    @objc public var inputAccessoryButtonTint: UIColor {
        switch identifier {
        case .light, .sepia, .widgetLight:
            return .gray600
        case .dark, .black, .widgetDark:
            return .gray100
        }
    }

    @objc public var inputAccessoryButtonSelectedTint: UIColor {
        return primaryText
    }
    
    @objc public var inputAccessoryButtonSelectedBackgroundColor: UIColor {
        return baseBackground
    }
    
    public var diffTextAdd: UIColor {
        switch identifier {
        case .light:
            return .gray700
        default:
            return .green600
        }
    }

    public var diffTextDelete: UIColor {
        switch identifier {
        case .light:
            return .gray700
        case .sepia:
            return.red700
        case .dark, .black:
            return .red600
        default:
            return .clear
        }
    }

    public var diffHighlightAdd: UIColor? {
        switch identifier {
        case .light:
            return .green100
        default:
            return nil
        }
    }

    public var diffHighlightDelete: UIColor? {
        switch identifier {
        case .light:
            return .red100
        default:
            return nil
        }
    }

    public var diffStrikethroughColor: UIColor {
        switch identifier {
        case .light:
            return .gray700
        case .sepia:
            return .red700
        case .dark, .black:
            return .red600
        default:
            return .clear
        }
    }

    public var  diffContextItemBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .beige300
        case .dark, .black, .widgetDark:
            return .gray700
        }
    }

    public var diffContextItemBorder: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray400
        case .sepia:
            return .taupe200
        case .dark, .widgetDark:
            return .gray650
        case .black:
            return .gray675
        }
    }

    public var diffMoveParagraphBackground: UIColor {
        switch identifier {
        case .light, .widgetLight:
            return .gray100
        case .sepia:
            return .beige300
        case .dark, .black, .widgetDark:
            return .gray700
        }
    }

    public var diffCompareAccent: UIColor {
        return .orange600
    }

    public var diffCompareChangeHeading: UIColor {
        switch identifier {
        case .light:
            return .white
        case .sepia:
            return .beige100
        case .black, .dark:
            return .black
        default:
             return .clear
        }
    }

    public var talkPageCoffeRollBackground: UIColor {
        switch identifier {
        case .light:
            return .beige100
        case .sepia:
            return .beige400
        case .dark, .black:
            return .gray800
        default:
            return .clear
        }
    }
    
    init(identifier: Identifier) {
        self.identifier = identifier
    }

    public enum Identifier {
        case light
        case sepia
        case dark
        case black
        case widgetLight
        case widgetDark
    }

}

@objc(WMFTheme)
public class Theme: NSObject {
    
    @objc public static let standard = Theme.light
    
    @objc public let colors: Colors
    
    @objc public let isDark: Bool
    
    @objc public let hasInputAccessoryShadow: Bool
    
    @objc public var preferredStatusBarStyle: UIStatusBarStyle {
        return isDark ? .lightContent : .default
    }
    
    @objc public var scrollIndicatorStyle: UIScrollView.IndicatorStyle {
        return isDark ? .white : .black
    }
    
    @objc public var blurEffectStyle: UIBlurEffect.Style {
        return isDark ? .dark : .light
    }
    
    @objc public var keyboardAppearance: UIKeyboardAppearance {
        return isDark ? .dark : .light
    }
    
    @objc public lazy var navigationBarBackgroundImage: UIImage = {
        return UIImage.wmf_image(from: colors.paperBackground)
    }()
    
    @objc public lazy var sheetNavigationBarBackgroundImage: UIImage = {
        return UIImage.wmf_image(from: colors.chromeBackground)
    }()
    
    @objc public lazy var editorNavigationBarBackgroundImage: UIImage = {
        return UIImage.wmf_image(from: colors.inputAccessoryBackground)
    }()
    
    @objc public var navigationBarShadowImage: UIImage {
        return clearImage
    }
    
    @objc public lazy var clearImage: UIImage = {
        return #imageLiteral(resourceName: "transparent-pixel")
    }()
    
    static let tabBarItemBadgeParagraphStyle: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0.4
        return paragraphStyle
    }()
    
    static let tabBarItemFont: UIFont = {
        return UIFont.systemFont(ofSize: 12)
    }()
    
    public lazy var tabBarItemBadgeTextAttributes: [NSAttributedString.Key: Any] = {
        return [NSAttributedString.Key.foregroundColor: colors.chromeBackground, NSAttributedString.Key.paragraphStyle: Theme.tabBarItemBadgeParagraphStyle]
    }()
    
    public lazy var tabBarTitleTextAttributes: [NSAttributedString.Key: Any] = {
        return [.foregroundColor: colors.secondaryText, .font: Theme.tabBarItemFont]
    }()
    
    public lazy var tabBarSelectedTitleTextAttributes: [NSAttributedString.Key: Any] = {
        return [.foregroundColor: colors.link, .font: Theme.tabBarItemFont]
    }()
    
    public static let exploreCardCornerRadius: CGFloat = 10
    
    static func roundedRectImage(with color: UIColor, cornerRadius: CGFloat, width: CGFloat? = nil, height: CGFloat? = nil) -> UIImage? {
        let minDimension = 2 * cornerRadius + 1
        let rect = CGRect(x: 0, y: 0, width: width ?? minDimension, height: height ?? minDimension)
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(color.cgColor)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.fill()
        let capInsets = UIEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        let image = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: capInsets)
        UIGraphicsEndImageContext()
        return image
    }
    
    @objc public lazy var searchFieldBackgroundImage: UIImage? = {
        return Theme.roundedRectImage(with: colors.searchFieldBackground, cornerRadius: 10, height: 36)
    }()
    
    @objc public lazy var navigationBarTitleTextAttributes: [NSAttributedString.Key: Any] = {
        return [NSAttributedString.Key.foregroundColor: colors.chromeText]
    }()
    
    public static let dimmedImageOpacity: CGFloat = 0.65
    @objc public let imageOpacity: CGFloat
    @objc public let cardBorderWidthInPixels: Int
    @objc public let cardShadowOpacity: Float
    
    @objc public let name: String
    @objc public let displayName: String
    public let analyticsName: String
    public let webName: String
    
    @objc public let multiSelectIndicatorImage: UIImage?
    fileprivate static let lightMultiSelectIndicator = UIImage(named: "selected", in: Bundle.main, compatibleWith:nil)
    fileprivate static let darkMultiSelectIndicator = UIImage(named: "selected-dark", in: Bundle.main, compatibleWith:nil)
    
    private static let defaultCardBorderWidthInPixels: Int = 1
    private static let lightCardBorderWidthInPixels: Int = {
        return DeviceInfo.shared.isOlderDevice ? 4 : defaultCardBorderWidthInPixels
    }()
    
    private static let defaultCardShadowOpacity: Float = {
        return DeviceInfo.shared.isOlderDevice ? 0 : 0.13
    }()
    
    @objc public static let defaultThemeName = "standard"
    @objc public static let defaultAnalyticsThemeName = "default"
    
    private static let darkThemePrefix = "dark"
    private static let blackThemePrefix = "black"
    
    @objc public static func isDefaultThemeName(_ name: String?) -> Bool {
        guard let name = name else {
            return true
        }
        return name == defaultThemeName
    }
    
    @objc public static func isDarkThemeName(_ name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        return name.hasPrefix(darkThemePrefix) || name.hasPrefix(blackThemePrefix)
    }
    
    @objc public static let light = Theme(colors: .light, imageOpacity: 1, cardBorderWidthInPixels: Theme.lightCardBorderWidthInPixels, cardShadowOpacity: defaultCardShadowOpacity, multiSelectIndicatorImage: Theme.lightMultiSelectIndicator, isDark: false, hasInputAccessoryShadow: true, name: "light", displayName: WMFLocalizedString("theme-light-display-name", value: "Light", comment: "Light theme name presented to the user"), analyticsName: "default", webName: "light")
    
    @objc public static let sepia = Theme(colors: .sepia, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.lightMultiSelectIndicator, isDark: false, hasInputAccessoryShadow: false, name: "sepia", displayName: WMFLocalizedString("theme-sepia-display-name", value: "Sepia", comment: "Sepia theme name presented to the user"), analyticsName: "sepia", webName: "sepia")
    
    @objc public static let dark = Theme(colors: .dark, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: darkThemePrefix, displayName: WMFLocalizedString("theme-dark-display-name", value: "Dark", comment: "Dark theme name presented to the user"), analyticsName: "dark", webName: "dark")
    
    @objc public static let darkDimmed = Theme(colors: .dark, imageOpacity: Theme.dimmedImageOpacity, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: "\(darkThemePrefix)-dimmed", displayName: Theme.dark.displayName,  analyticsName: "dark", webName: "dark")
    
    @objc public static let black = Theme(colors: .black, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: blackThemePrefix, displayName: WMFLocalizedString("theme-black-display-name", value: "Black", comment: "Black theme name presented to the user"),  analyticsName: "black", webName: "black")
    
    @objc public static let blackDimmed = Theme(colors: .black, imageOpacity: Theme.dimmedImageOpacity, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: "\(blackThemePrefix)-dimmed", displayName: Theme.black.displayName,  analyticsName: "black", webName: "black")
    
    @objc public static let widgetLight = Theme(colors: .widgetLight, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: nil, isDark: false, hasInputAccessoryShadow: false, name: "widget-light", displayName: "", analyticsName: "", webName: "light")
    
    @objc public static let widgetDark = Theme(colors: .widgetDark, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: nil, isDark: false, hasInputAccessoryShadow: false, name: "widget-dark", displayName: "", analyticsName: "", webName: "black")
    
    public class func widgetThemeCompatible(with traitCollection: UITraitCollection) -> Theme {
        return traitCollection.userInterfaceStyle == .dark ? Theme.widgetDark : Theme.widgetLight
    }
    
    init(colors: Colors, imageOpacity: CGFloat, cardBorderWidthInPixels: Int, cardShadowOpacity: Float, multiSelectIndicatorImage: UIImage?, isDark: Bool, hasInputAccessoryShadow: Bool, name: String, displayName: String, analyticsName: String, webName: String) {
        self.colors = colors
        self.imageOpacity = imageOpacity
        self.name = name
        self.displayName = displayName
        self.multiSelectIndicatorImage = multiSelectIndicatorImage
        self.isDark = isDark
        self.hasInputAccessoryShadow = hasInputAccessoryShadow
        self.cardBorderWidthInPixels = cardBorderWidthInPixels
        self.cardShadowOpacity = cardShadowOpacity
        self.analyticsName = analyticsName
        self.webName = webName
    }
    
    fileprivate static let themesByName = [Theme.light.name: Theme.light, Theme.dark.name: Theme.dark, Theme.sepia.name: Theme.sepia, Theme.darkDimmed.name: Theme.darkDimmed, Theme.black.name: Theme.black, Theme.blackDimmed.name: Theme.blackDimmed]
    
    @objc(withName:)
    public class func withName(_ name: String?) -> Theme? {
        guard let name = name else {
            return nil
        }
        return themesByName[name]
    }
    
    @objc public func withDimmingEnabled(_ isDimmingEnabled: Bool) -> Theme {
        guard let baseName = name.components(separatedBy: "-").first else {
            return self
        }
        let adjustedName = isDimmingEnabled ? "\(baseName)-dimmed" : baseName
        return Theme.withName(adjustedName) ?? self
    }
}

@objc(WMFThemeable)
public protocol Themeable: AnyObject {
    @objc(applyTheme:)
    func apply(theme: Theme) // this might be better as a var theme: Theme { get set } - common VC superclasses could check for viewIfLoaded and call an update method in the setter. This would elminate the need for the viewIfLoaded logic in every applyTheme:
}

// Use for SwiftUI environment objects
public final class ObservableTheme: ObservableObject {
    @Published public var theme: Theme

    public init(theme: Theme) {
        self.theme = theme
    }
}

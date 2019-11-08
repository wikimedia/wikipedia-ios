import Foundation
import SystemConfiguration

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
        var int = UInt32()
        guard hex.count == 6, Scanner(string: hex).scanHexInt32(&int) && int != UINT32_MAX else {
            assertionFailure("Unexpected issue scanning hex string: \(hexString)")
            self.init(white: 0, alpha: alpha)
            return
        }
        self.init(Int(int), alpha: alpha)
    }
    
    fileprivate static let defaultShadow = UIColor(white: 0, alpha: 0.25)

    fileprivate static let pitchBlack = UIColor(0x101418)

    fileprivate static let base10 = UIColor(0x222222)
    fileprivate static let base20 = UIColor(0x54595D)
    static let battleshipGray = UIColor(0x72777D)
    fileprivate static let base50 = UIColor(0xA2A9B1)
    fileprivate static let base70 = UIColor(0xC8CCD1)
    fileprivate static let base80 = UIColor(0xEAECF0)
    fileprivate static let base90 = UIColor(0xF8F9FA)
    fileprivate static let base100 = UIColor(0xFFFFFF)
    fileprivate static let red30 = UIColor(0xB32424)
    fileprivate static let red50 = UIColor(0xCC3333)
    fileprivate static let red75 = UIColor(0xFF6E6E)
    fileprivate static let yellow50 = UIColor(0xFFCC33)
    fileprivate static let green50 = UIColor(0x00AF89)
    fileprivate static let blue10 = UIColor(0x2A4B8D)
    fileprivate static let blue50 = UIColor(0x3366CC)
    fileprivate static let lightBlue = UIColor(0xEAF3FF)
    fileprivate static let mesosphere = UIColor(0x43464A)
    static let thermosphere = UIColor(0x2E3136)
    fileprivate static let stratosphere = UIColor(0x6699FF)
    fileprivate static let exosphere = UIColor(0x27292D)
    fileprivate static let accent = UIColor(0x00AF89)
    fileprivate static let accent10 = UIColor(0x2A4B8D)
    fileprivate static let amate = UIColor(0xE1DAD1)
    fileprivate static let parchment = UIColor(0xF8F1E3)
    fileprivate static let masi = UIColor(0x646059)
    fileprivate static let papyrus = UIColor(0xF0E6D6)
    fileprivate static let kraft = UIColor(0xCBC8C1)
    static let osage = UIColor(0xFF9500)
    static let osage15PercentAlpha = UIColor(0xFF9500, alpha: 0.15)
    fileprivate static let sand = UIColor(0xE8DCCA)
    fileprivate static let palenavy = UIColor(0xEEF2FB)
    
    fileprivate static let darkSearchFieldBackground = UIColor(0x8E8E93, alpha: 0.12)
    fileprivate static let lightSearchFieldBackground = UIColor(0xFFFFFF, alpha: 0.15)

    fileprivate static let masi60PercentAlpha = UIColor(0x646059, alpha:0.6)
    fileprivate static let black15PercentAlpha = UIColor(white: 0, alpha:0.15)
    fileprivate static let black40PercentAlpha = UIColor(white: 0, alpha:0.4)
    fileprivate static let black50PercentAlpha = UIColor(0x000000, alpha:0.5)
    fileprivate static let black75PercentAlpha = UIColor(0x000000, alpha:0.75)
    fileprivate static let white15PercentAlpha = UIColor(white: 1, alpha:0.15)
    fileprivate static let white20PercentAlpha = UIColor(white: 1, alpha:0.2)
    fileprivate static let white40PercentAlpha = UIColor(white: 1, alpha:0.4)

    fileprivate static let base70At55PercentAlpha = base70.withAlphaComponent(0.55)
    fileprivate static let blue50At10PercentAlpha = UIColor(0x3366CC, alpha:0.1)
    fileprivate static let blue50At25PercentAlpha = UIColor(0x3366CC, alpha:0.25)

    @objc static let wmf_darkGray = UIColor(0x4D4D4B)
    @objc static let wmf_lightGray = UIColor(0x9AA0A7)
    @objc static let wmf_gray = UIColor.base70
    @objc static let wmf_lighterGray = UIColor.base80
    @objc static let wmf_lightestGray = UIColor(0xF5F5F5) // also known as refresh gray
    fileprivate static let wmf_lightBlueGray = UIColor(0xE8E9EB)

    @objc static let wmf_darkBlue = UIColor.blue10
    @objc static let wmf_blue = UIColor.blue50
    @objc static let wmf_lightBlue = UIColor.lightBlue

    @objc static let wmf_green = UIColor.green50
    @objc static let wmf_lightGreen = UIColor(0xD5FDF4)

    @objc static let wmf_red = UIColor.red50
    @objc static let wmf_lightRed = UIColor(0xFFE7E6)
    
    @objc static let wmf_yellow = UIColor.yellow50
    @objc static let wmf_lightYellow = UIColor(0xFEF6E7)
    
    @objc static let wmf_orange = UIColor(0xFF5B00)
    
    @objc static let wmf_purple = UIColor(0x7F4AB3)
    @objc static let wmf_lightPurple = UIColor(0xF3E6FF)

    @objc func wmf_hexStringIncludingAlpha(_ includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        var hexString = String(format: "%02X%02X%02X", Int(255.0 * r), Int(255.0 * g), Int(255.0 * b))
        if (includeAlpha) {
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
    fileprivate static let light = Colors(baseBackground: .base80, midBackground: .base90, paperBackground: .base100, chromeBackground: .base100,  popoverBackground: .base100, subCellBackground: .base100, overlayBackground: .black50PercentAlpha, batchSelectionBackground: .lightBlue, referenceHighlightBackground: .clear, hintBackground: .lightBlue, hintWarningBackground: .wmf_lightYellow, animationBackground: .palenavy, overlayText: .base20, searchFieldBackground: .darkSearchFieldBackground, keyboardBarSearchFieldBackground: .base80, primaryText: .base10, secondaryText: .battleshipGray, tertiaryText: .base70, disabledText: .base80, disabledLink: .battleshipGray, chromeText: .base10, link: .blue50, accent: .green50, border: .base80, shadow: .base80, chromeShadow: .defaultShadow, cardBackground: .base100, selectedCardBackground: .base90, cardBorder: .wmf_lightestGray, cardShadow: .base10, cardButtonBackground: .wmf_lightestGray, secondaryAction: .blue10, icon: nil, iconBackground: nil, destructive: .red50, error: .red50, warning: .osage, unselected: .base50, blurEffectStyle: .extraLight, blurEffectBackground: .clear, tagText: .blue50, tagBackground: .blue50At10PercentAlpha, tagSelectedBackground: .blue50At25PercentAlpha, rankGradientStart: .blue50, rankGradientEnd: .green50, distanceBorder: .base50, descriptionBackground: .yellow50, descriptionWarning: .osage, inputAccessoryBackground: .base100, inputAccessoryButtonTint: .base20, pageIndicator: .lightBlue, pageIndicatorCurrent: .blue50, unreadIndicator: .green50, depthMarker: .base70, diffTextAdd: .base10, diffTextDelete: .base10, diffHighlightAdd: .wmf_lightGreen, diffHighlightDelete: .wmf_lightRed, diffStrikethroughColor: .black, diffContextItemBackground: .wmf_lightestGray, diffContextItemBorder: .wmf_lightBlueGray, diffMoveParagraphBackground: .wmf_lightestGray, diffCompareAccent: .osage, diffCompareChangeHeading: .white)

    fileprivate static let sepia = Colors(baseBackground: .amate, midBackground: .papyrus, paperBackground: .parchment, chromeBackground: .parchment, popoverBackground: .base100, subCellBackground: .papyrus, overlayBackground: .masi60PercentAlpha, batchSelectionBackground: .lightBlue, referenceHighlightBackground: .clear, hintBackground: .lightBlue, hintWarningBackground: .amate, animationBackground: .palenavy, overlayText: .base20, searchFieldBackground: .darkSearchFieldBackground, keyboardBarSearchFieldBackground: .base80, primaryText: .base10, secondaryText: .masi, tertiaryText: .masi, disabledText: .base80, disabledLink: .masi, chromeText: .base10, link: .blue50, accent: .green50, border: .kraft, shadow: .kraft,  chromeShadow: .base20, cardBackground: .papyrus, selectedCardBackground: .amate, cardBorder: .sand, cardShadow: .clear,  cardButtonBackground: .amate, secondaryAction: .accent10, icon: .masi, iconBackground: .amate, destructive: .red30, error: .red30, warning: .osage, unselected: .masi, blurEffectStyle: .extraLight, blurEffectBackground: .clear, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50, rankGradientStart: .blue50, rankGradientEnd: .blue50, distanceBorder: .masi, descriptionBackground: .osage, descriptionWarning: .osage, inputAccessoryBackground: .papyrus, inputAccessoryButtonTint: .base20, pageIndicator: .lightBlue, pageIndicatorCurrent: .blue50, unreadIndicator: .green50, depthMarker: .masi, diffTextAdd: .green50, diffTextDelete: .red75, diffHighlightAdd: nil, diffHighlightDelete: nil, diffStrikethroughColor: .red75, diffContextItemBackground: .papyrus, diffContextItemBorder: .sand, diffMoveParagraphBackground: .papyrus, diffCompareAccent: .osage, diffCompareChangeHeading: .white)
    
    fileprivate static let dark = Colors(baseBackground: .base10, midBackground: .exosphere, paperBackground: .thermosphere, chromeBackground: .mesosphere, popoverBackground: .base10, subCellBackground: .exosphere, overlayBackground: .black75PercentAlpha, batchSelectionBackground: .accent10, referenceHighlightBackground: .clear, hintBackground: .pitchBlack, hintWarningBackground: .base10, animationBackground: .base10, overlayText: .base20, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .thermosphere, primaryText: .base90, secondaryText: .base70, tertiaryText: .base70, disabledText: .base70, disabledLink: .base70, chromeText: .base90, link: .stratosphere, accent: .green50, border: .mesosphere, shadow: .base10, chromeShadow: .base10, cardBackground: .exosphere, selectedCardBackground: .base10, cardBorder: .thermosphere, cardShadow: .clear, cardButtonBackground: .mesosphere, secondaryAction: .accent10, icon: .base70, iconBackground: .exosphere, destructive: .red75, error: .red75, warning: .yellow50, unselected: .base70, blurEffectStyle: .dark, blurEffectBackground: .base70At55PercentAlpha, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50, rankGradientStart: .stratosphere, rankGradientEnd: .green50, distanceBorder: .base70, descriptionBackground: .stratosphere, descriptionWarning: .yellow50, inputAccessoryBackground: .exosphere, inputAccessoryButtonTint: .base90, pageIndicator: .lightBlue, pageIndicatorCurrent: .stratosphere, unreadIndicator: .green50, depthMarker: .base70, diffTextAdd: .green50, diffTextDelete: .red75, diffHighlightAdd: nil, diffHighlightDelete: nil, diffStrikethroughColor: .red75, diffContextItemBackground: .exosphere, diffContextItemBorder: .exosphere, diffMoveParagraphBackground: .mesosphere, diffCompareAccent: .osage, diffCompareChangeHeading: .black)

    fileprivate static let black = Colors(baseBackground: .pitchBlack, midBackground: .base10, paperBackground: .black, chromeBackground: .base10, popoverBackground: .base10, subCellBackground: .base10, overlayBackground: .black75PercentAlpha, batchSelectionBackground: .accent10, referenceHighlightBackground: .white20PercentAlpha, hintBackground: .thermosphere, hintWarningBackground: .pitchBlack, animationBackground: .base10, overlayText: .base20, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .thermosphere, primaryText: .base90, secondaryText: .base70, tertiaryText: .base70, disabledText: .base70, disabledLink: .base70, chromeText: .base90, link: .stratosphere, accent: .green50, border: .mesosphere, shadow: .base10, chromeShadow: .base10, cardBackground: .base10, selectedCardBackground: .pitchBlack, cardBorder: .exosphere, cardShadow: .clear, cardButtonBackground: .thermosphere, secondaryAction: .accent10, icon: .base70, iconBackground: .exosphere, destructive: .red75, error: .red75, warning: .yellow50, unselected: .base70, blurEffectStyle: .dark, blurEffectBackground: .base70At55PercentAlpha, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50, rankGradientStart: .stratosphere, rankGradientEnd: .green50, distanceBorder: .base70, descriptionBackground: .stratosphere, descriptionWarning: .yellow50, inputAccessoryBackground: .exosphere, inputAccessoryButtonTint: .base90, pageIndicator: .lightBlue, pageIndicatorCurrent: .stratosphere, unreadIndicator: .green50, depthMarker: .base70, diffTextAdd: .green50, diffTextDelete: .red75, diffHighlightAdd: nil, diffHighlightDelete: nil, diffStrikethroughColor: .red75, diffContextItemBackground: .base10, diffContextItemBorder: .base10, diffMoveParagraphBackground: .thermosphere, diffCompareAccent: .osage, diffCompareChangeHeading: .black)
    
    fileprivate static let widgetLight = Colors(baseBackground: .clear, midBackground: .clear, paperBackground: .clear, chromeBackground: .clear,  popoverBackground: .clear, subCellBackground: .clear, overlayBackground: UIColor(white: 1.0, alpha: 0.4), batchSelectionBackground: .lightBlue, referenceHighlightBackground: .clear, hintBackground: .clear, hintWarningBackground: .clear, animationBackground: .palenavy, overlayText: .base20, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .base80, primaryText: .base10, secondaryText: .base10, tertiaryText: .base20, disabledText: .battleshipGray, disabledLink: .base70, chromeText: .base10, link: .accent10, accent: .green50, border: UIColor(white: 0, alpha: 0.15) , shadow: .base80, chromeShadow: .base80, cardBackground: .black, selectedCardBackground: .base10, cardBorder: .clear, cardShadow: .black, cardButtonBackground: .black, secondaryAction: .blue10, icon: nil, iconBackground: nil, destructive: .red50, error: .red50, warning: .yellow50, unselected: .base50, blurEffectStyle: .extraLight, blurEffectBackground: .clear, tagText: .clear, tagBackground: .clear, tagSelectedBackground: .clear, rankGradientStart: .accent10, rankGradientEnd: .green50, distanceBorder: .base50, descriptionBackground: .osage, descriptionWarning: .osage, inputAccessoryBackground: .black, inputAccessoryButtonTint: .base90, pageIndicator: .lightBlue, pageIndicatorCurrent: .accent10, unreadIndicator: .green50, depthMarker: .base20, diffTextAdd: .base10, diffTextDelete: .base10, diffHighlightAdd: .wmf_lightGreen, diffHighlightDelete: .wmf_lightRed, diffStrikethroughColor: .base10, diffContextItemBackground: .wmf_lightestGray, diffContextItemBorder: .wmf_lightBlueGray, diffMoveParagraphBackground: .wmf_lightestGray, diffCompareAccent: .osage, diffCompareChangeHeading: .white)
    
    fileprivate static let widgetDark = Colors(baseBackground: .clear, midBackground: .clear, paperBackground: .clear, chromeBackground: .clear, popoverBackground: .clear, subCellBackground: .clear, overlayBackground: .black40PercentAlpha, batchSelectionBackground: .accent10, referenceHighlightBackground: .white20PercentAlpha, hintBackground: .thermosphere, hintWarningBackground: .clear, animationBackground: .palenavy, overlayText: .base70, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .thermosphere, primaryText: .base90, secondaryText: .base70, tertiaryText: .base70, disabledText: .base70, disabledLink: .base70, chromeText: .base90, link: .stratosphere, accent: .green50, border: .white15PercentAlpha, shadow: .base10, chromeShadow: .base10, cardBackground: .base10, selectedCardBackground: .pitchBlack, cardBorder: .exosphere, cardShadow: .clear, cardButtonBackground: .thermosphere, secondaryAction: .accent10, icon: .base70, iconBackground: .exosphere, destructive: .red75, error: .red75, warning: .yellow50, unselected: .base70, blurEffectStyle: .dark, blurEffectBackground: .base70At55PercentAlpha, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50, rankGradientStart: .stratosphere, rankGradientEnd: .green50, distanceBorder: .base70, descriptionBackground: .stratosphere, descriptionWarning: .yellow50, inputAccessoryBackground: .exosphere, inputAccessoryButtonTint: .base90, pageIndicator: .lightBlue, pageIndicatorCurrent: .stratosphere, unreadIndicator: .green50, depthMarker: .base70, diffTextAdd: .green50, diffTextDelete: .red75, diffHighlightAdd: nil, diffHighlightDelete: nil, diffStrikethroughColor: .red75, diffContextItemBackground: .exosphere, diffContextItemBorder: .exosphere, diffMoveParagraphBackground: .thermosphere, diffCompareAccent: .osage, diffCompareChangeHeading: .white)

    @objc public let baseBackground: UIColor
    @objc public let midBackground: UIColor
    @objc public let subCellBackground: UIColor
    @objc public let paperBackground: UIColor
    @objc public let popoverBackground: UIColor
    @objc public let chromeBackground: UIColor
    @objc public let chromeShadow: UIColor
    @objc public let overlayBackground: UIColor
    @objc public let batchSelectionBackground: UIColor
    @objc public let referenceHighlightBackground: UIColor
    @objc public let hintBackground: UIColor
    @objc public let hintWarningBackground: UIColor
    @objc public let animationBackground: UIColor

    @objc public let overlayText: UIColor

    @objc public let primaryText: UIColor
    @objc public let secondaryText: UIColor
    @objc public let tertiaryText: UIColor
    @objc public let disabledText: UIColor
    @objc public let disabledLink: UIColor
    
    @objc public let chromeText: UIColor
    
    @objc public let link: UIColor
    @objc public let accent: UIColor
    @objc public let secondaryAction: UIColor
    @objc public let destructive: UIColor
    @objc public let warning: UIColor
    @objc public let error: UIColor
    @objc public let unselected: UIColor

    @objc public let border: UIColor
    @objc public let shadow: UIColor
    public let cardBackground: UIColor
    public let selectedCardBackground: UIColor
    
    @objc public let cardBorder: UIColor
    @objc public let cardShadow: UIColor
    @objc public let cardButtonBackground: UIColor

    @objc public let icon: UIColor?
    @objc public let iconBackground: UIColor?
    
    @objc public let searchFieldBackground: UIColor
    @objc public let keyboardBarSearchFieldBackground: UIColor

    @objc public let rankGradientStart: UIColor
    @objc public let rankGradientEnd: UIColor
    @objc public let rankGradient: Gradient
    
    @objc public let blurEffectStyle: UIBlurEffect.Style
    @objc public let blurEffectBackground: UIColor
    
    @objc public let tagText: UIColor
    @objc public let tagBackground: UIColor
    @objc public let tagSelectedBackground: UIColor

    @objc public let distanceBorder: UIColor
    @objc public let descriptionBackground: UIColor
    @objc public let descriptionWarning: UIColor
    
    @objc public let pageIndicator: UIColor
    @objc public let pageIndicatorCurrent: UIColor
    
    @objc public let unreadIndicator: UIColor
    
    @objc public let depthMarker: UIColor
    
    @objc public var refreshControlTint: UIColor {
        return secondaryText
    }

    @objc public let inputAccessoryBackground: UIColor
    @objc public let inputAccessoryButtonTint: UIColor
    @objc public var inputAccessoryButtonSelectedTint: UIColor {
        return primaryText
    }
    @objc public var inputAccessoryButtonSelectedBackgroundColor: UIColor {
        return baseBackground
    }
    
    public let diffTextAdd: UIColor
    public let diffTextDelete: UIColor
    public let diffHighlightAdd: UIColor?
    public let diffHighlightDelete: UIColor?
    public let diffStrikethroughColor: UIColor
    public let diffContextItemBackground: UIColor
    public let diffContextItemBorder: UIColor
    public let diffMoveParagraphBackground: UIColor
    public let diffCompareAccent: UIColor
    public let diffCompareChangeHeading: UIColor
    
    //Someday, when the app is all swift, make this class a struct.
    init(baseBackground: UIColor, midBackground: UIColor, paperBackground: UIColor, chromeBackground: UIColor, popoverBackground: UIColor, subCellBackground: UIColor, overlayBackground: UIColor, batchSelectionBackground: UIColor, referenceHighlightBackground: UIColor, hintBackground: UIColor, hintWarningBackground: UIColor, animationBackground: UIColor, overlayText: UIColor, searchFieldBackground: UIColor, keyboardBarSearchFieldBackground: UIColor, primaryText: UIColor, secondaryText: UIColor, tertiaryText: UIColor, disabledText: UIColor, disabledLink: UIColor, chromeText: UIColor, link: UIColor, accent: UIColor, border: UIColor, shadow: UIColor, chromeShadow: UIColor, cardBackground: UIColor, selectedCardBackground: UIColor, cardBorder: UIColor, cardShadow: UIColor, cardButtonBackground: UIColor, secondaryAction: UIColor, icon: UIColor?, iconBackground: UIColor?, destructive: UIColor, error: UIColor, warning: UIColor, unselected: UIColor, blurEffectStyle: UIBlurEffect.Style, blurEffectBackground: UIColor, tagText: UIColor, tagBackground: UIColor, tagSelectedBackground: UIColor, rankGradientStart: UIColor, rankGradientEnd: UIColor, distanceBorder: UIColor, descriptionBackground: UIColor, descriptionWarning: UIColor, inputAccessoryBackground: UIColor, inputAccessoryButtonTint: UIColor, pageIndicator: UIColor, pageIndicatorCurrent: UIColor, unreadIndicator: UIColor, depthMarker: UIColor, diffTextAdd: UIColor, diffTextDelete: UIColor, diffHighlightAdd: UIColor?, diffHighlightDelete: UIColor?, diffStrikethroughColor: UIColor, diffContextItemBackground: UIColor, diffContextItemBorder: UIColor, diffMoveParagraphBackground: UIColor, diffCompareAccent: UIColor, diffCompareChangeHeading: UIColor) {
        self.baseBackground = baseBackground
        self.midBackground = midBackground
        self.subCellBackground = subCellBackground
        self.paperBackground = paperBackground
        self.popoverBackground = popoverBackground
        self.chromeBackground = chromeBackground
        self.chromeShadow = chromeShadow
        self.cardBackground = cardBackground
        self.selectedCardBackground = selectedCardBackground
        self.cardBorder = cardBorder
        self.cardShadow = cardShadow
        self.cardButtonBackground = cardButtonBackground
        self.overlayBackground = overlayBackground
        self.batchSelectionBackground = batchSelectionBackground
        self.hintBackground = hintBackground
        self.hintWarningBackground = hintWarningBackground
        self.animationBackground = animationBackground
        self.referenceHighlightBackground = referenceHighlightBackground

        self.overlayText = overlayText
        
        self.searchFieldBackground = searchFieldBackground
        self.keyboardBarSearchFieldBackground = keyboardBarSearchFieldBackground
        
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.tertiaryText = tertiaryText
        self.disabledText = disabledText
        self.disabledLink = disabledLink

        self.chromeText = chromeText

        self.link = link
        self.accent = accent
        
        self.border = border
        self.shadow = shadow
        
        self.icon = icon
        self.iconBackground = iconBackground

        self.rankGradientStart = rankGradientStart
        self.rankGradientEnd = rankGradientEnd
        self.rankGradient = Gradient(startColor: rankGradientStart, endColor: rankGradientEnd)
        
        self.error = error
        self.warning = warning
        self.destructive = destructive
        self.secondaryAction = secondaryAction
        self.unselected = unselected
        
        self.blurEffectStyle = blurEffectStyle
        self.blurEffectBackground = blurEffectBackground

        self.tagText = tagText
        self.tagBackground = tagBackground
        self.tagSelectedBackground = tagSelectedBackground
        
        self.distanceBorder = distanceBorder
        self.descriptionBackground = descriptionBackground
        self.descriptionWarning = descriptionWarning

        self.inputAccessoryBackground = inputAccessoryBackground
        self.inputAccessoryButtonTint = inputAccessoryButtonTint
        
        self.pageIndicator = pageIndicator
        self.pageIndicatorCurrent = pageIndicatorCurrent
        
        self.unreadIndicator = unreadIndicator
        self.depthMarker = depthMarker
        
        self.diffTextAdd = diffTextAdd
        self.diffTextDelete = diffTextDelete
        self.diffHighlightAdd = diffHighlightAdd
        self.diffHighlightDelete = diffHighlightDelete
        self.diffStrikethroughColor = diffStrikethroughColor
        self.diffContextItemBackground = diffContextItemBackground
        self.diffContextItemBorder = diffContextItemBorder
        self.diffMoveParagraphBackground = diffMoveParagraphBackground
        self.diffCompareAccent = diffCompareAccent
        self.diffCompareChangeHeading = diffCompareChangeHeading
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
    
    @objc public static let light = Theme(colors: .light, imageOpacity: 1, cardBorderWidthInPixels: Theme.lightCardBorderWidthInPixels, cardShadowOpacity: defaultCardShadowOpacity, multiSelectIndicatorImage: Theme.lightMultiSelectIndicator, isDark: false, hasInputAccessoryShadow: true, name: "light", displayName: WMFLocalizedString("theme-light-display-name", value: "Light", comment: "Light theme name presented to the user"), analyticsName: "light", webName: "light")
    
    @objc public static let sepia = Theme(colors: .sepia, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.lightMultiSelectIndicator, isDark: false, hasInputAccessoryShadow: false, name: "sepia", displayName: WMFLocalizedString("theme-sepia-display-name", value: "Sepia", comment: "Sepia theme name presented to the user"), analyticsName: "sepia", webName: "sepia")
    
    @objc public static let dark = Theme(colors: .dark, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: darkThemePrefix, displayName: WMFLocalizedString("theme-dark-display-name", value: "Dark", comment: "Dark theme name presented to the user"), analyticsName: "dark", webName: "dark")
    
    @objc public static let darkDimmed = Theme(colors: .dark, imageOpacity: Theme.dimmedImageOpacity, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: "\(darkThemePrefix)-dimmed", displayName: Theme.dark.displayName,  analyticsName: "dark", webName: "dark")

    @objc public static let black = Theme(colors: .black, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: blackThemePrefix, displayName: WMFLocalizedString("theme-black-display-name", value: "Black", comment: "Black theme name presented to the user"),  analyticsName: "black", webName: "black")

    @objc public static let blackDimmed = Theme(colors: .black, imageOpacity: Theme.dimmedImageOpacity, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, hasInputAccessoryShadow: false, name: "\(blackThemePrefix)-dimmed", displayName: Theme.black.displayName,  analyticsName: "black", webName: "black")

    @objc public static let widgetLight = Theme(colors: .widgetLight, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: nil, isDark: false, hasInputAccessoryShadow: false, name: "widget-light", displayName: "", analyticsName: "", webName: "light")
    
    @objc public static let widgetDark = Theme(colors: .widgetDark, imageOpacity: 1, cardBorderWidthInPixels: Theme.defaultCardBorderWidthInPixels, cardShadowOpacity: 0, multiSelectIndicatorImage: nil, isDark: false, hasInputAccessoryShadow: false, name: "widget-dark", displayName: "", analyticsName: "", webName: "black")
    
    public class func widgetThemeCompatible(with traitCollection: UITraitCollection) -> Theme {
        if #available(iOSApplicationExtension 13.0, *) {
            return traitCollection.userInterfaceStyle == .dark ? Theme.widgetDark : Theme.widgetLight
        } else {
            return Theme.widgetLight
        }
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
public protocol Themeable : class {
    @objc(applyTheme:)
    func apply(theme: Theme) //this might be better as a var theme: Theme { get set } - common VC superclasses could check for viewIfLoaded and call an update method in the setter. This would elminate the need for the viewIfLoaded logic in every applyTheme:
}

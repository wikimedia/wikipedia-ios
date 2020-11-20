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
    
    // Wikimedia Style Guide Colors
    // https://design.wikimedia.org/style-guide/visual-style_colors.html
    
    static let base0 = UIColor(0x000000)
    static let base10 = UIColor(0x202122)
    static let base20 = UIColor(0x54595D)
    static let base30 = UIColor(0x72777D) // formerly battleship grey
    static let base50 = UIColor(0xA2A9B1)
    static let base70 = UIColor(0xC8CCD1)
    static let base80 = UIColor(0xEAECF0)
    static let base90 = UIColor(0xF8F9FA)
    static let base100 = UIColor(0xFFFFFF)
    
    static let blue30 = UIColor(0x2A4B8D)
    static let blue50 = UIColor(0x3366CC)
    static let blue70 = UIColor(0x6699FF) // app-specific, formerly stratosphere
    static let blue90 = UIColor(0xEAF3FF)
    
    static let accent30 = blue30
    static let accent50 = blue50
    static let accent70 = blue70
    static let accent90 = blue90
    
    static let red30 = UIColor(0xB32424)
    static let red50 = UIColor(0xDD3333)
    static let red75 = UIColor(0xFF6E6E)
    static let red90 = UIColor(0xFEE7E6)
    
    static let green30 = UIColor(0x14866D)
    @objc(wmf_green50) static let green50 = UIColor(0x00AF89)
    static let green90 = UIColor(0xD5FDF4)
    
    // static let yellow30 = UIColor(0xAC6600) unused
    static let yellow50 = UIColor(0xFFCC33)
    static let yellow90 = UIColor(0xFEF6E7)
    
    // App specific colors

    static let darkBase05 = UIColor(0x101418) // pitchBlack
    static let darkBase10 = UIColor(0x27292D) // exosphere
    static let darkBase20 = UIColor(0x2E3136) // thermosphere
    static let darkBase30 = UIColor(0x43464A) // mesosphere
    static let darkBase90 = UIColor(0xE8E9EB) // wmf_lightBlueGray
    
    static let sepiaBase85 = UIColor(0xE1DAD1) // amate
    static let sepiaBase90 = UIColor(0xF0E6D6) // papyrus
    static let sepiaBase100 = UIColor(0xF8F1E3) // parchment

    static let sepiaBorder = UIColor(0xE8DCCA) // sand
    
    static let lightBorder = UIColor(0xF5F5F5) // wmf_lightestGray

    static let sepiaGray40 = UIColor(0x646059) // masi
    static let sepiaGray80 = UIColor(0xCBC8C1) // kraft
    
    static let purple50 = UIColor(0x7F4AB3)
    static let purple90 = UIColor(0xF3E6FF)
    
    static let orange50 = UIColor(0xFF9500)
    
    static let paleNavy = UIColor(0xEEF2FB)
    
    static let darkSearchFieldBackground = UIColor(0x8E8E93, alpha: 0.12)
    static let lightSearchFieldBackground = UIColor(0xFFFFFF, alpha: 0.15)
    
    static let black25PercentAlpha = UIColor(white: 0, alpha: 0.25)
    static let black40PercentAlpha = UIColor(white: 0, alpha:0.4)
    static let black50PercentAlpha = UIColor(white: 0, alpha:0.5)
    static let black75PercentAlpha = UIColor(white: 0, alpha:0.75)
    static let white15PercentAlpha = UIColor(white: 1, alpha:0.15)
    static let white20PercentAlpha = UIColor(white: 1, alpha:0.2)
    static let white40PercentAlpha = UIColor(white: 1, alpha:0.4)
    
    static let base70At55PercentAlpha = base70.withAlphaComponent(0.55)
    
    static let accent50At10PercentAlpha = accent50.withAlphaComponent(0.1)
    static let accent50At25PercentAlpha = accent50.withAlphaComponent(0.25)
    
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
    fileprivate static let light = Colors(
        baseBackground: .base80,
        midBackground: .base90,
        paperBackground: .base100,
        chromeBackground: .base100,
        popoverBackground: .base100,
        subCellBackground: .base100,
        overlayBackground: .black50PercentAlpha,
        batchSelectionBackground: .accent90,
        referenceHighlightBackground: .clear,
        hintBackground: .accent90,
        hintWarningBackground: .yellow90,
        animationBackground: .paleNavy,
        overlayText: .base20,
        searchFieldBackground: .darkSearchFieldBackground,
        keyboardBarSearchFieldBackground: .base80,
        primaryText: .base10,
        secondaryText: .base30,
        tertiaryText: .base70,
        disabledText: .base80,
        disabledLink: .base30,
        chromeText: .base10,
        link: .accent50,
        accent: .green50,
        border: .base80,
        shadow: .base80,
        chromeShadow: .black25PercentAlpha,
        cardBackground: .base100,
        selectedCardBackground: .base90,
        cardBorder: .lightBorder,
        cardShadow: .base10,
        cardButtonBackground: .lightBorder,
        cardButtonSelectedBackground: .accent90,
        secondaryAction: .accent30,
        icon: nil,
        iconBackground: nil,
        destructive: .red50,
        error: .red50,
        warning: .orange50,
        unselected: .base50,
        blurEffectStyle: .extraLight,
        blurEffectBackground: .clear,
        tagText: .accent50,
        tagBackground: .accent50At10PercentAlpha,
        tagSelectedBackground: .accent50At25PercentAlpha,
        rankGradientStart: .accent50,
        rankGradientEnd: .green50,
        distanceBorder: .base50,
        descriptionBackground: .yellow50,
        descriptionWarning: .orange50,
        inputAccessoryBackground: .base100,
        inputAccessoryButtonTint: .base20,
        pageIndicator: .accent90,
        pageIndicatorCurrent: .accent50,
        unreadIndicator: .green50,
        depthMarker: .base70,
        diffTextAdd: .base10,
        diffTextDelete: .base10,
        diffHighlightAdd: .green90,
        diffHighlightDelete: .red90,
        diffStrikethroughColor: .base0,
        diffContextItemBackground: .lightBorder,
        diffContextItemBorder: .darkBase90,
        diffMoveParagraphBackground: .lightBorder,
        diffCompareAccent: .orange50,
        diffCompareChangeHeading: .base100)
    
    fileprivate static let sepia = Colors(
        baseBackground: .sepiaBase85,
        midBackground: .sepiaBase90,
        paperBackground: .sepiaBase100,
        chromeBackground: .sepiaBase100,
        popoverBackground: .base100,
        subCellBackground: .sepiaBase90,
        overlayBackground: UIColor.sepiaGray40.withAlphaComponent(0.6),
        batchSelectionBackground: .accent90,
        referenceHighlightBackground: .clear,
        hintBackground: .accent90,
        hintWarningBackground: .sepiaBase85,
        animationBackground: .paleNavy,
        overlayText: .base20,
        searchFieldBackground: .darkSearchFieldBackground,
        keyboardBarSearchFieldBackground: .base80,
        primaryText: .base10,
        secondaryText: .sepiaGray40,
        tertiaryText: .sepiaGray40,
        disabledText: .base80,
        disabledLink: .sepiaGray40,
        chromeText: .base10,
        link: .accent50,
        accent: .green50,
        border: .sepiaGray80,
        shadow: .sepiaGray80,
        chromeShadow: .base20,
        cardBackground: .sepiaBase90,
        selectedCardBackground: .sepiaBase85,
        cardBorder: .sepiaBorder,
        cardShadow: .clear,
        cardButtonBackground: .sepiaBase90,
        cardButtonSelectedBackground: .sepiaGray80,
        secondaryAction: .accent30,
        icon: .sepiaGray40,
        iconBackground: .sepiaBase85,
        destructive: .red30,
        error: .red30,
        warning: .orange50,
        unselected: .sepiaGray40,
        blurEffectStyle: .extraLight,
        blurEffectBackground: .clear,
        tagText: .base100,
        tagBackground: .accent70,
        tagSelectedBackground: .accent50,
        rankGradientStart: .accent50,
        rankGradientEnd: .accent50,
        distanceBorder: .sepiaGray40,
        descriptionBackground: .orange50,
        descriptionWarning: .orange50,
        inputAccessoryBackground: .sepiaBase90,
        inputAccessoryButtonTint: .base20,
        pageIndicator: .accent90,
        pageIndicatorCurrent: .accent50,
        unreadIndicator: .green50,
        depthMarker: .sepiaGray40,
        diffTextAdd: .green50,
        diffTextDelete: .red30,
        diffHighlightAdd: nil,
        diffHighlightDelete: nil,
        diffStrikethroughColor: .red30,
        diffContextItemBackground: .sepiaBase90,
        diffContextItemBorder: .sepiaBorder,
        diffMoveParagraphBackground: .sepiaBase90,
        diffCompareAccent: .orange50,
        diffCompareChangeHeading: .base100)
    
    fileprivate static let dark = Colors(
        baseBackground: .base10,
        midBackground: .darkBase10,
        paperBackground: .darkBase20,
        chromeBackground: .darkBase30,
        popoverBackground: .base10,
        subCellBackground: .darkBase10,
        overlayBackground: .black75PercentAlpha,
        batchSelectionBackground: .accent30,
        referenceHighlightBackground: .clear,
        hintBackground: .darkBase05,
        hintWarningBackground: .base10,
        animationBackground: .base10,
        overlayText: .base20,
        searchFieldBackground: .lightSearchFieldBackground,
        keyboardBarSearchFieldBackground: .darkBase20,
        primaryText: .base90,
        secondaryText: .base70,
        tertiaryText: .base70,
        disabledText: .base70,
        disabledLink: .base70,
        chromeText: .base90,
        link: .accent70,
        accent: .green50,
        border: .darkBase30,
        shadow: .base10,
        chromeShadow: .base10,
        cardBackground: .darkBase10,
        selectedCardBackground: .base10,
        cardBorder: .darkBase20,
        cardShadow: .clear,
        cardButtonBackground: .darkBase30,
        cardButtonSelectedBackground: .base10,
        secondaryAction: .accent30,
        icon: .base70,
        iconBackground: .darkBase10,
        destructive: .red75,
        error: .red75,
        warning: .yellow50,
        unselected: .base70,
        blurEffectStyle: .dark,
        blurEffectBackground: .base70At55PercentAlpha,
        tagText: .base100,
        tagBackground: .accent70,
        tagSelectedBackground: .accent50,
        rankGradientStart: .accent70,
        rankGradientEnd: .green50,
        distanceBorder: .base70,
        descriptionBackground: .accent70,
        descriptionWarning: .yellow50,
        inputAccessoryBackground: .darkBase10,
        inputAccessoryButtonTint: .base90,
        pageIndicator: .accent90,
        pageIndicatorCurrent: .accent70,
        unreadIndicator: .green50,
        depthMarker: .base70,
        diffTextAdd: .green50,
        diffTextDelete: .red75,
        diffHighlightAdd: nil,
        diffHighlightDelete: nil,
        diffStrikethroughColor: .red75,
        diffContextItemBackground: .darkBase10,
        diffContextItemBorder: .darkBase10,
        diffMoveParagraphBackground: .darkBase30,
        diffCompareAccent: .orange50,
        diffCompareChangeHeading: .base0)
    
    fileprivate static let black = Colors(
        baseBackground: .darkBase05,
        midBackground: .base10,
        paperBackground: .base0,
        chromeBackground: .base10,
        popoverBackground: .base10,
        subCellBackground: .base10,
        overlayBackground: .black75PercentAlpha,
        batchSelectionBackground: .accent30,
        referenceHighlightBackground: .white20PercentAlpha,
        hintBackground: .darkBase20,
        hintWarningBackground: .darkBase05,
        animationBackground: .base10,
        overlayText: .base20,
        searchFieldBackground: .lightSearchFieldBackground,
        keyboardBarSearchFieldBackground: .darkBase20,
        primaryText: .base90,
        secondaryText: .base70,
        tertiaryText: .base70,
        disabledText: .base70,
        disabledLink: .base70,
        chromeText: .base90,
        link: .accent70,
        accent: .green50,
        border: .darkBase30,
        shadow: .base10,
        chromeShadow: .base10,
        cardBackground: .base10,
        selectedCardBackground: .darkBase05,
        cardBorder: .darkBase10,
        cardShadow: .clear,
        cardButtonBackground: .darkBase30,
        cardButtonSelectedBackground: .base10,
        secondaryAction: .accent30,
        icon: .base70,
        iconBackground: .darkBase10,
        destructive: .red75,
        error: .red75,
        warning: .yellow50,
        unselected: .base70,
        blurEffectStyle: .dark,
        blurEffectBackground: .base70At55PercentAlpha,
        tagText: .base100,
        tagBackground: .accent70,
        tagSelectedBackground: .accent50,
        rankGradientStart: .accent70,
        rankGradientEnd: .green50,
        distanceBorder: .base70,
        descriptionBackground: .accent70,
        descriptionWarning: .yellow50,
        inputAccessoryBackground: .darkBase10,
        inputAccessoryButtonTint: .base90,
        pageIndicator: .accent90,
        pageIndicatorCurrent: .accent70,
        unreadIndicator: .green50,
        depthMarker: .base70,
        diffTextAdd: .green50,
        diffTextDelete: .red75,
        diffHighlightAdd: nil,
        diffHighlightDelete: nil,
        diffStrikethroughColor: .red75,
        diffContextItemBackground: .base10,
        diffContextItemBorder: .base10,
        diffMoveParagraphBackground: .darkBase20,
        diffCompareAccent: .orange50,
        diffCompareChangeHeading: .base0)
    
    fileprivate static let widgetLight = Colors(
        baseBackground: .clear,
        midBackground: .clear,
        paperBackground: .clear,
        chromeBackground: .clear,
        popoverBackground: .clear,
        subCellBackground: .clear,
        overlayBackground: UIColor(white: 1.0, alpha: 0.4),
        batchSelectionBackground: .accent90,
        referenceHighlightBackground: .clear,
        hintBackground: .clear,
        hintWarningBackground: .clear,
        animationBackground: .paleNavy,
        overlayText: .base20,
        searchFieldBackground: .lightSearchFieldBackground,
        keyboardBarSearchFieldBackground: .base80,
        primaryText: .base10,
        secondaryText: .base10,
        tertiaryText: .base20,
        disabledText: .base30,
        disabledLink: .base70,
        chromeText: .base10,
        link: .accent30,
        accent: .green50,
        border: UIColor(white: 0, alpha: 0.15),
        shadow: .base80,
        chromeShadow: .base80,
        cardBackground: .base0,
        selectedCardBackground: .base10,
        cardBorder: .clear,
        cardShadow: .base0,
        cardButtonBackground: .base0,
        cardButtonSelectedBackground: .base80,
        secondaryAction: .accent30,
        icon: nil,
        iconBackground: nil,
        destructive: .red50,
        error: .red50,
        warning: .yellow50,
        unselected: .base50,
        blurEffectStyle: .extraLight,
        blurEffectBackground: .clear,
        tagText: .clear,
        tagBackground: .clear,
        tagSelectedBackground: .clear,
        rankGradientStart: .accent30,
        rankGradientEnd: .green50,
        distanceBorder: .base50,
        descriptionBackground: .orange50,
        descriptionWarning: .orange50,
        inputAccessoryBackground: .base0,
        inputAccessoryButtonTint: .base90,
        pageIndicator: .accent90,
        pageIndicatorCurrent: .accent30,
        unreadIndicator: .green50,
        depthMarker: .base20)
    
    fileprivate static let widgetDark = Colors(
        baseBackground: .clear,
        midBackground: .clear,
        paperBackground: .clear,
        chromeBackground: .clear,
        popoverBackground: .clear,
        subCellBackground: .clear,
        overlayBackground: .black40PercentAlpha,
        batchSelectionBackground: .accent30,
        referenceHighlightBackground: .white20PercentAlpha,
        hintBackground: .darkBase20,
        hintWarningBackground: .clear,
        animationBackground: .paleNavy,
        overlayText: .base70,
        searchFieldBackground: .lightSearchFieldBackground,
        keyboardBarSearchFieldBackground: .darkBase20,
        primaryText: .base90,
        secondaryText: .base70,
        tertiaryText: .base70,
        disabledText: .base70,
        disabledLink: .base70,
        chromeText: .base90,
        link: .accent70,
        accent: .green50,
        border: .white15PercentAlpha,
        shadow: .base10,
        chromeShadow: .base10,
        cardBackground: .base10,
        selectedCardBackground: .darkBase05,
        cardBorder: .darkBase10,
        cardShadow: .clear,
        cardButtonBackground: .darkBase20,
        cardButtonSelectedBackground: .base10,
        secondaryAction: .accent30,
        icon: .base70,
        iconBackground: .darkBase10,
        destructive: .red75,
        error: .red75,
        warning: .yellow50,
        unselected: .base70,
        blurEffectStyle: .dark,
        blurEffectBackground: .base70At55PercentAlpha,
        tagText: .base100,
        tagBackground: .accent70,
        tagSelectedBackground: .accent50,
        rankGradientStart: .accent70,
        rankGradientEnd: .green50,
        distanceBorder: .base70,
        descriptionBackground: .accent70,
        descriptionWarning: .yellow50,
        inputAccessoryBackground: .darkBase10,
        inputAccessoryButtonTint: .base90,
        pageIndicator: .accent90,
        pageIndicatorCurrent: .accent70,
        unreadIndicator: .green50,
        depthMarker: .base70)
    
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
    @objc public let cardButtonSelectedBackground: UIColor
    
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
    init(baseBackground: UIColor, midBackground: UIColor, paperBackground: UIColor, chromeBackground: UIColor, popoverBackground: UIColor, subCellBackground: UIColor, overlayBackground: UIColor, batchSelectionBackground: UIColor, referenceHighlightBackground: UIColor, hintBackground: UIColor, hintWarningBackground: UIColor, animationBackground: UIColor, overlayText: UIColor, searchFieldBackground: UIColor, keyboardBarSearchFieldBackground: UIColor, primaryText: UIColor, secondaryText: UIColor, tertiaryText: UIColor, disabledText: UIColor, disabledLink: UIColor, chromeText: UIColor, link: UIColor, accent: UIColor, border: UIColor, shadow: UIColor, chromeShadow: UIColor, cardBackground: UIColor, selectedCardBackground: UIColor, cardBorder: UIColor, cardShadow: UIColor, cardButtonBackground: UIColor, cardButtonSelectedBackground: UIColor, secondaryAction: UIColor, icon: UIColor?, iconBackground: UIColor?, destructive: UIColor, error: UIColor, warning: UIColor, unselected: UIColor, blurEffectStyle: UIBlurEffect.Style, blurEffectBackground: UIColor, tagText: UIColor, tagBackground: UIColor, tagSelectedBackground: UIColor, rankGradientStart: UIColor, rankGradientEnd: UIColor, distanceBorder: UIColor, descriptionBackground: UIColor, descriptionWarning: UIColor, inputAccessoryBackground: UIColor, inputAccessoryButtonTint: UIColor, pageIndicator: UIColor, pageIndicatorCurrent: UIColor, unreadIndicator: UIColor, depthMarker: UIColor, diffTextAdd: UIColor = .base10, diffTextDelete: UIColor = .base10, diffHighlightAdd: UIColor? = .green90, diffHighlightDelete: UIColor? = .red90, diffStrikethroughColor: UIColor = .base0, diffContextItemBackground: UIColor = .base90, diffContextItemBorder: UIColor = .darkBase90, diffMoveParagraphBackground: UIColor = .base90, diffCompareAccent: UIColor = .orange50, diffCompareChangeHeading: UIColor = .base100) {
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
        self.cardButtonSelectedBackground = cardButtonSelectedBackground
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

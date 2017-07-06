import Foundation

@objc(WMFThemeColors)
public class ThemeColors: NSObject {
    fileprivate static let base10 = UIColor.wmf_color(withHex: 0x222222)!
    fileprivate static let base70 = UIColor.wmf_color(withHex: 0xC8CCD1)!
    fileprivate static let base90 = UIColor.wmf_color(withHex: 0xF8F9FA)!
    
    fileprivate static let mesophere = UIColor.wmf_color(withHex: 0x43464A)!
    fileprivate static let thermosphere = UIColor.wmf_color(withHex: 0x2E3136)!
    fileprivate static let stratosphere = UIColor.wmf_color(withHex: 0x6699FF)!
    fileprivate static let exosphere = UIColor.wmf_color(withHex: 0x27292D)!
    fileprivate static let accent = UIColor.wmf_color(withHex: 0x00AF89)!
    
    fileprivate static let dark = ThemeColors(baseBackground: ThemeColors.base10, midBackground: ThemeColors.exosphere, paperBackground: ThemeColors.thermosphere, chromeBackground: ThemeColors.mesophere, primaryText: ThemeColors.base90, secondaryText: ThemeColors.base90, tertiaryText: ThemeColors.base70, chromeText: ThemeColors.base90, link: ThemeColors.stratosphere, accent: ThemeColors.accent, border: ThemeColors.mesophere, shadow: ThemeColors.mesophere, icon: ThemeColors.base70, iconBackground: ThemeColors.exosphere)
    
    fileprivate static let light = ThemeColors(baseBackground: .wmf_settingsBackground, midBackground: .wmf_lightGrayCellBackground, paperBackground: .white, chromeBackground: .white, primaryText: .black, secondaryText: UIColor.wmf_color(withHex: 0x555555), tertiaryText: .wmf_customGray, chromeText: .wmf_navigationGray, link: .wmf_blue, accent: .wmf_green, border: ThemeColors.base10 , shadow: ThemeColors.base10, icon: nil, iconBackground: nil)
    
    public let baseBackground: UIColor
    public let midBackground: UIColor
    public let paperBackground: UIColor
    public let chromeBackground: UIColor
    
    public let primaryText: UIColor
    public let secondaryText: UIColor
    public let tertiaryText: UIColor
    
    public let chromeText: UIColor
    
    public let link: UIColor
    public let accent: UIColor

    public let border: UIColor
    public let shadow: UIColor
    
    public let icon: UIColor?
    public let iconBackground: UIColor?
    
    public let linkToAccent: Gradient
    
    init(baseBackground: UIColor, midBackground: UIColor, paperBackground: UIColor, chromeBackground: UIColor, primaryText: UIColor, secondaryText: UIColor, tertiaryText: UIColor, chromeText: UIColor, link: UIColor, accent: UIColor, border: UIColor, shadow: UIColor, icon: UIColor?, iconBackground: UIColor?) {
        self.baseBackground = baseBackground
        self.midBackground = midBackground
        self.paperBackground = paperBackground
        self.chromeBackground = chromeBackground
        
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.tertiaryText = tertiaryText
        
        self.chromeText = chromeText

        self.link = link
        self.accent = accent
        
        self.border = border
        self.shadow = shadow
        
        self.icon = icon
        self.iconBackground = iconBackground
        
        self.linkToAccent = Gradient(startColor: link, endColor: accent)
    }
}

@objc(WMFTheme)
public class Theme: NSObject {
    
    public let colors: ThemeColors
    
    public let preferredStatusBarStyle: UIStatusBarStyle
    
    public static let light = Theme(colors: ThemeColors.light, preferredStatusBarStyle: .default)
    public static let dark = Theme(colors: ThemeColors.dark, preferredStatusBarStyle: .lightContent)
    
    public static let standard = Theme.light
    
    init(colors: ThemeColors, preferredStatusBarStyle: UIStatusBarStyle) {
        self.colors = colors
        self.preferredStatusBarStyle = preferredStatusBarStyle
    }
}

@objc(WMFThemeable)
public protocol Themeable : NSObjectProtocol {
    @objc(applyTheme:)
    func apply(theme: Theme)
}

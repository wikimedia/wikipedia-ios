import Foundation

public extension UIColor {
    public convenience init(_ hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    @objc(initWithHexInteger:)
    public convenience init(_ hex: Int) {
        self.init(hex, alpha: 1)
    }
    
    public class func wmf_colorWithHex(_ hex: Int) -> UIColor {
        return UIColor(hex)
    }

    fileprivate static let base10 = UIColor(0x222222)
    fileprivate static let base20 = UIColor(0x54595D)
    fileprivate static let base30 = UIColor(0x72777D)
    fileprivate static let base70 = UIColor(0xC8CCD1)
    fileprivate static let base80 = UIColor(0xEAECF0)
    fileprivate static let base90 = UIColor(0xF8F9FA)
    fileprivate static let base100 = UIColor(0xFFFFFF)
    fileprivate static let red30 = UIColor(0xB32424)
    fileprivate static let red50 = UIColor(0xCC3333)
    fileprivate static let yellow50 = UIColor(0xFFCC33)
    fileprivate static let green50 = UIColor(0x00AF89)
    fileprivate static let blue10 = UIColor(0x2A4B8D)
    fileprivate static let blue50 = UIColor(0x3366CC)
    fileprivate static let mesophere = UIColor(0x43464A)
    fileprivate static let thermosphere = UIColor(0x2E3136)
    fileprivate static let stratosphere = UIColor(0x6699FF)
    fileprivate static let exosphere = UIColor(0x27292D)
    fileprivate static let accent = UIColor(0x00AF89)
    fileprivate static let battleshipGray = UIColor(0x72777D)
    fileprivate static let x555555 = UIColor(0x555555)
    fileprivate static let sunsetRed = UIColor(0xFF6E6E)
    fileprivate static let accent10 = UIColor(0x2A4B8D)
    
    fileprivate static let amate = UIColor(0xE1DAD1)
    fileprivate static let parchment = UIColor(0xF8F1E3)
    fileprivate static let masi = UIColor(0x646059)
    fileprivate static let papyrus = UIColor(0xF0E6D6)
    fileprivate static let kraft = UIColor(0xCBC8C1)
    fileprivate static let osage = UIColor(0xFF9500)
    
    public static let wmf_baseBackground = UIColor(0xEFEFF4)
    public static let wmf_midBackground = UIColor(0xF8F9FA)
    public static let wmf_white = UIColor(0xFFFFFF)
    public static let wmf_black = UIColor(0x000000)
    public static let wmf_lightestGray = UIColor(0xF5F5F5) // also known as refresh gray
    public static let wmf_lightGray = UIColor(0x9AA0A7)
    public static let wmf_midGray = UIColor(0x555555)
    public static let wmf_darkGray = UIColor(0x4D4D4B)
    public static let wmf_blue = UIColor(0x3366CC)
    public static let wmf_green = UIColor(0x00AF89)
    public static let wmf_darkBlue = UIColor(0x2A4B8D)
    public static let wmf_red = UIColor(0xCC3333)
    public static let wmf_lightRed = UIColor(0xFFE7E6)
    public static let wmf_yellow = UIColor(0xFFCC33)
    public static let wmf_lightYellow = UIColor(0xFEF6E7)
    public static let wmf_orange = UIColor(0xFF5B00)
    public static let wmf_purple = UIColor(0x7F4AB3)
    public static let wmf_lightPurple = UIColor(0xF3E6FF)
    public static let wmf_lightBlue = UIColor(0xEAF3FF)
    public static let wmf_lightGreen = UIColor(0xD5FDF4)
    public static let wmf_777777 = UIColor(0x777777)

    public func wmf_hexStringIncludingAlpha(_ includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        var hexString = String(format: "%02x%02x%02x", Int(255.0 * r), Int(255.0 * g), Int(255.0 * b))
        if (includeAlpha) {
            hexString = hexString.appendingFormat("%02x", Int(255.0 * a))
        }
        return hexString
    }
}

@objc(WMFColors)
public class Colors: NSObject {
    fileprivate static let light = Colors(baseBackground: .base80, midBackground: .base90, paperBackground: .base100, chromeBackground: .base100, primaryText: .base10, secondaryText: .base30, tertiaryText: .base70, chromeText: .base20, link: .blue50, accent: .green50, border: .base70 , shadow: .base80, secondaryAction: .blue10, icon: nil, iconBackground: nil, destructive: .red50, error: .red50, warning: .yellow50)

    fileprivate static let sepia = Colors(baseBackground: .amate, midBackground: .papyrus, paperBackground: .parchment, chromeBackground: .parchment, primaryText: .base10, secondaryText: .masi, tertiaryText: .base70, chromeText: .base20, link: .blue50, accent: .green50, border: .kraft, shadow: .kraft, secondaryAction: .accent10, icon: .masi, iconBackground: .amate, destructive: .red30, error: .red30, warning: .osage)
    
    fileprivate static let dark = Colors(baseBackground: .base10, midBackground: .exosphere, paperBackground: .thermosphere, chromeBackground: .mesophere, primaryText: .base90, secondaryText: .base70, tertiaryText: .base70, chromeText: .base90, link: .stratosphere, accent: .green50, border: .mesophere, shadow: .mesophere, secondaryAction: .accent10, icon: .base70, iconBackground: .exosphere, destructive: .sunsetRed, error: .sunsetRed, warning: .yellow50)
    
    
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
    public let secondaryAction: UIColor
    public let destructive: UIColor
    public let warning: UIColor
    public let error: UIColor
    
    public let border: UIColor
    public let shadow: UIColor
    
    public let icon: UIColor?
    public let iconBackground: UIColor?
    
    public let linkToAccent: Gradient
    
    //Someday, when the app is all swift, make this class a struct.
    init(baseBackground: UIColor, midBackground: UIColor, paperBackground: UIColor, chromeBackground: UIColor, primaryText: UIColor, secondaryText: UIColor, tertiaryText: UIColor, chromeText: UIColor, link: UIColor, accent: UIColor, border: UIColor, shadow: UIColor, secondaryAction: UIColor, icon: UIColor?, iconBackground: UIColor?, destructive: UIColor, error: UIColor, warning: UIColor) {
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
        
        self.error = error
        self.warning = warning
        self.destructive = destructive
        self.secondaryAction = secondaryAction
    }
}


@objc(WMFTheme)
public class Theme: NSObject {
    public let colors: Colors
    
    public let preferredStatusBarStyle: UIStatusBarStyle
    public let blurEffectStyle: UIBlurEffectStyle
    public let keyboardAppearance: UIKeyboardAppearance
    
    public static let light = Theme(colors: .light, preferredStatusBarStyle: .default, blurEffectStyle: .light, keyboardAppearance: .light, name: "Default")
    
    public static let sepia = Theme(colors: .sepia, preferredStatusBarStyle: .default, blurEffectStyle: .light, keyboardAppearance: .light, name: "Sepia")
    
    public static let dark = Theme(colors: .dark, preferredStatusBarStyle: .lightContent, blurEffectStyle: .dark, keyboardAppearance: .dark, name: "Dark")
    
    fileprivate static let themesByName = [Theme.light.name: Theme.light, Theme.dark.name: Theme.dark, Theme.sepia.name: Theme.sepia]
    
    @objc(themeWithName:)
    public class func theme(with name: String?) -> Theme {
        guard let name = name else {
            return Theme.standard
        }
        return themesByName[name] ?? Theme.standard
    }
    
    public static let standard = Theme.light
    
    public let name: String
    
    init(colors: Colors, preferredStatusBarStyle: UIStatusBarStyle, blurEffectStyle: UIBlurEffectStyle, keyboardAppearance: UIKeyboardAppearance, name: String) {
        self.colors = colors
        self.preferredStatusBarStyle = preferredStatusBarStyle
        self.blurEffectStyle = blurEffectStyle
        self.keyboardAppearance = keyboardAppearance
        self.name = name
    }
}

@objc(WMFThemeable)
public protocol Themeable : NSObjectProtocol {
    @objc(applyTheme:)
    func apply(theme: Theme) //this might be better as a var theme: Theme { get set } - common VC superclasses could check for viewIfLoaded and call an update method in the setter. This would elminate the need for the viewIfLoaded logic in every applyTheme:
}

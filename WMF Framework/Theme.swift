import Foundation

@objc(WMFTheme)
public class Theme: NSObject {
   
    public let farBackground: UIColor
    public let midBackground: UIColor
    public let paper: UIColor
    public let chrome: UIColor
    public let chromeText: UIColor
    
    public let text: UIColor
    public let secondaryText: UIColor
    public let link: UIColor
    public let accent: UIColor
    
    public let preferredStatusBarStyle: UIStatusBarStyle
    
    public static var light = Theme(farBackground: .wmf_settingsBackground, midBackground: .wmf_lightGrayCellBackground, paper: .white, chrome: .white, chromeText: .wmf_navigationGray, text: .black, secondaryText: .wmf_customGray, link: .wmf_blue, accent: .wmf_green, preferredStatusBarStyle: .default)
    public static var dark = Theme(farBackground: UIColor.wmf_color(withHex: 0x222222), midBackground: UIColor.wmf_color(withHex: 0x303030), paper: .black, chrome: .black, chromeText: UIColor.wmf_color(withHex: 0xf8f9fa), text: UIColor.wmf_color(withHex: 0xf8f9fa), secondaryText: .lightGray, link: UIColor.wmf_color(withHex: 0x6087d7), accent: UIColor.wmf_color(withHex: 0x00af89), preferredStatusBarStyle: .lightContent)
    
    init(farBackground: UIColor, midBackground: UIColor, paper: UIColor, chrome: UIColor, chromeText: UIColor, text: UIColor, secondaryText: UIColor, link: UIColor, accent: UIColor, preferredStatusBarStyle: UIStatusBarStyle) {
        self.farBackground = farBackground
        self.midBackground = midBackground
        self.paper = paper
        self.chrome = chrome
        self.chromeText = chromeText
        self.text = text
        self.secondaryText = secondaryText
        self.link = link
        self.accent = accent
        self.preferredStatusBarStyle = preferredStatusBarStyle
    }
}

@objc(WMFThemeable)
public protocol Themeable : NSObjectProtocol {
    @objc(applyTheme:)
    func apply(theme: Theme)
}

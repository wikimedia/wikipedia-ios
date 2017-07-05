import Foundation

@objc(WMFTheme)
public class Theme: NSObject {
   
    public let farBackground: UIColor
    public let midBackground: UIColor
    public let paper: UIColor
    public let chrome: UIColor
    
    public let text: UIColor
    public let secondaryText: UIColor
    public let link: UIColor
    public let accent: UIColor
    
    public static var light = Theme(farBackground: .wmf_settingsBackground, midBackground: .wmf_lightGrayCellBackground, paper: .white, chrome: .white, text: .black, secondaryText: .wmf_customGray, link: .wmf_blue, accent: .wmf_green)
    public static var dark = Theme(farBackground: .darkGray, midBackground: .gray, paper: .black, chrome: .darkGray, text: .white, secondaryText: .lightGray, link: .wmf_orange, accent: .wmf_green)
    
    init(farBackground: UIColor, midBackground: UIColor, paper: UIColor, chrome: UIColor, text: UIColor, secondaryText: UIColor, link: UIColor, accent: UIColor) {
        self.farBackground = farBackground
        self.midBackground = midBackground
        self.paper = paper
        self.chrome = chrome
        self.text = text
        self.secondaryText = secondaryText
        self.link = link
        self.accent = accent
    }
}

@objc(WMFThemeable)
public protocol Themeable : NSObjectProtocol {
    @objc(applyTheme:)
    func apply(theme: Theme)
}

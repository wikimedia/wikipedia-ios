import Foundation

@objc(WMFTheme)
public class Theme: NSObject {
   
    let farBackground: UIColor
    let midBackground: UIColor
    let paper: UIColor
    let chrome: UIColor
    
    let text: UIColor
    let secondaryText: UIColor
    let link: UIColor
    let accent: UIColor
    
    public static var current = Theme(farBackground: .gray, midBackground: .lightGray, paper: .white, chrome: .white, text: .black, secondaryText: .gray, link: .blue, accent: .green)
    
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
    var theme: Theme { get set }
    func themeDidChange()
}


@objc(WMFView)
class View: UIView, Themeable {
    public var theme: Theme = Theme.current {
        didSet {
            themeDidChange()
        }
    }
    
    func themeDidChange() {
        
    }
}

@objc(WMFViewController)
class ViewController: UIViewController, Themeable {
    public var theme: Theme = Theme.current {
        didSet {
            themeDidChange()
        }
    }
    
    func themeDidChange() {
        
    }
}


@objc(WMFTableViewController)
class TableViewController: UITableViewController, Themeable {
    public var theme: Theme = Theme.current {
        didSet {
            themeDidChange()
        }
    }
    
    func themeDidChange() {
        
    }
}


@objc(WMFCollectionViewController)
class CollectionViewController: UICollectionViewController, Themeable {
    public var theme: Theme = Theme.current {
        didSet {
            themeDidChange()
        }
    }
    
    func themeDidChange() {
        
    }
}


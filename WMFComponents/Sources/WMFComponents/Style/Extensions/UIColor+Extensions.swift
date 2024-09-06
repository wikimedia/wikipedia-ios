import UIKit

public extension UIColor {

    /// Allows UIColor to be initialized with hex value
    /// Example: UIColor(0x101010)

    convenience init(_ hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    convenience init(_ hex: Int) {
        self.init(hex, alpha: 1)
    }
	
}

import UIKit

@objc(WMFGradient)
public class Gradient: NSObject {
    fileprivate var r1: CGFloat = 0
    fileprivate var g1: CGFloat = 0
    fileprivate var b1: CGFloat = 0
    fileprivate var a1: CGFloat = 0
    
    fileprivate var r2: CGFloat = 0
    fileprivate var g2: CGFloat = 0
    fileprivate var b2: CGFloat = 0
    fileprivate var a2: CGFloat = 0
    
    init(startColor: UIColor, endColor: UIColor) {
        startColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        super.init()
    }
    
    @objc(colorAtPercentage:)
    public final func color(at percentage: CGFloat) -> UIColor {
        let r = r1 + percentage * (r2 - r1)
        let g = g1 + percentage * (g2 - g1)
        let b = b1 + percentage * (b2 - b1)
        let a = a1 + percentage * (a2 - a1)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

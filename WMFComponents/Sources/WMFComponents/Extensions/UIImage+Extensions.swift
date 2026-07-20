import Foundation
import UIKit

public extension UIImage {
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
    
    static func gradientImage(startColor: UIColor, endColor: UIColor, size: CGSize = CGSize(width: 1, height: 100), startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        let colors = [startColor.cgColor, endColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) else { return nil }
        context.drawLinearGradient(gradient, start: CGPoint(x: size.width * startPoint.x, y: size.height * startPoint.y), end: CGPoint(x: size.width * endPoint.x, y: size.height * endPoint.y), options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }
}

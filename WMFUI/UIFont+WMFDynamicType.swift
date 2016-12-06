import UIKit

@objc public enum WMFFontFamily: Int {
    case System
    case Georgia
}

public extension UIFont {

    public class func preferredFontForFontFamily(fontFamily: WMFFontFamily, withTextStyle style: String, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont? {
        
        guard fontFamily != .System else {
            if #available(iOSApplicationExtension 10.0, *) {
                return UIFont.preferredFontForTextStyle(style, compatibleWithTraitCollection: traitCollection)
            } else {
                return UIFont.preferredFontForTextStyle(style)
            }
        }
        
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var fontSizeTable: [WMFFontFamily: [String: [String: CGFloat]]] = [:]
        }
        
        dispatch_once(&Static.onceToken) {
            Static.fontSizeTable = [
                .Georgia:
                [UIFontTextStyleTitle2: [
                    UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: 28,
                    UIContentSizeCategoryAccessibilityExtraExtraLarge: 28,
                    UIContentSizeCategoryAccessibilityExtraLarge: 28,
                    UIContentSizeCategoryAccessibilityLarge: 28,
                    UIContentSizeCategoryAccessibilityMedium: 28,
                    UIContentSizeCategoryExtraExtraExtraLarge: 26,
                    UIContentSizeCategoryExtraExtraLarge: 24,
                    UIContentSizeCategoryExtraLarge: 22,
                    UIContentSizeCategoryLarge: 22,
                    UIContentSizeCategoryMedium: 21,
                    UIContentSizeCategorySmall: 20,
                    UIContentSizeCategoryExtraSmall: 19
                ],
                UIFontTextStyleTitle3: [
                    UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: 26,
                    UIContentSizeCategoryAccessibilityExtraExtraLarge: 26,
                    UIContentSizeCategoryAccessibilityExtraLarge: 26,
                    UIContentSizeCategoryAccessibilityLarge: 26,
                    UIContentSizeCategoryAccessibilityMedium: 26,
                    UIContentSizeCategoryExtraExtraExtraLarge: 24,
                    UIContentSizeCategoryExtraExtraLarge: 22,
                    UIContentSizeCategoryExtraLarge: 20,
                    UIContentSizeCategoryLarge: 19,
                    UIContentSizeCategoryMedium: 18,
                    UIContentSizeCategorySmall: 17,
                    UIContentSizeCategoryExtraSmall: 16
                ]]
            ]
        }
        
        var preferredContentSizeCategory = UIContentSizeCategoryMedium
        if #available(iOSApplicationExtension 10.0, *) {
            preferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        }
        let size = Static.fontSizeTable[fontFamily]?[style]?[preferredContentSizeCategory] ?? 21
        let descriptor = UIFontDescriptor(name: "Georgia", size: size)
        return UIFont(descriptor: descriptor, size: 0)
    }
}

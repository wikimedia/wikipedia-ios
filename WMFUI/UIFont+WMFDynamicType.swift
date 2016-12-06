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
                    UIContentSizeCategoryLarge: 21,
                    UIContentSizeCategoryMedium: 20,
                    UIContentSizeCategorySmall: 19,
                    UIContentSizeCategoryExtraSmall: 18
                ],
                UIFontTextStyleTitle3: [
                    UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: 24,
                    UIContentSizeCategoryAccessibilityExtraExtraLarge: 24,
                    UIContentSizeCategoryAccessibilityExtraLarge: 24,
                    UIContentSizeCategoryAccessibilityLarge: 24,
                    UIContentSizeCategoryAccessibilityMedium: 24,
                    UIContentSizeCategoryExtraExtraExtraLarge: 22,
                    UIContentSizeCategoryExtraExtraLarge: 20,
                    UIContentSizeCategoryExtraLarge: 19,
                    UIContentSizeCategoryLarge: 18,
                    UIContentSizeCategoryMedium: 17,
                    UIContentSizeCategorySmall: 16,
                    UIContentSizeCategoryExtraSmall: 15
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

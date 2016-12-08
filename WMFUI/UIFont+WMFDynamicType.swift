import UIKit

@objc public enum WMFFontFamily: Int {
    case System
    case SystemBlack
    case SystemBold
    case Georgia
}

public extension UIFont {

    public class func wmf_preferredFontForFontFamily(fontFamily: WMFFontFamily, withTextStyle style: String) -> UIFont? {
        return UIFont.wmf_preferredFontForFontFamily(fontFamily, withTextStyle: style, compatibleWithTraitCollection: UIScreen.mainScreen().traitCollection)
    }
    
    public class func wmf_preferredFontForFontFamily(fontFamily: WMFFontFamily, withTextStyle style: String, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont? {
        
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
                .Georgia:[
                    UIFontTextStyleTitle2: [
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
                    ]
                ],
                .SystemBlack: [
                    UIFontTextStyleTitle1: [
                        UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: 38,
                        UIContentSizeCategoryAccessibilityExtraExtraLarge: 38,
                        UIContentSizeCategoryAccessibilityExtraLarge: 38,
                        UIContentSizeCategoryAccessibilityLarge: 38,
                        UIContentSizeCategoryAccessibilityMedium: 38,
                        UIContentSizeCategoryExtraExtraExtraLarge: 37,
                        UIContentSizeCategoryExtraExtraLarge: 36,
                        UIContentSizeCategoryExtraLarge: 35,
                        UIContentSizeCategoryLarge: 34,
                        UIContentSizeCategoryMedium: 33,
                        UIContentSizeCategorySmall: 32,
                        UIContentSizeCategoryExtraSmall: 31
                    ]
                ],
                .SystemBold: [
                    UIFontTextStyleSubheadline: [
                        UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: 21,
                        UIContentSizeCategoryAccessibilityExtraExtraLarge: 21,
                        UIContentSizeCategoryAccessibilityExtraLarge: 21,
                        UIContentSizeCategoryAccessibilityLarge: 21,
                        UIContentSizeCategoryAccessibilityMedium: 21,
                        UIContentSizeCategoryExtraExtraExtraLarge: 21,
                        UIContentSizeCategoryExtraExtraLarge: 19,
                        UIContentSizeCategoryExtraLarge: 17,
                        UIContentSizeCategoryLarge: 15,
                        UIContentSizeCategoryMedium: 14,
                        UIContentSizeCategorySmall: 13,
                        UIContentSizeCategoryExtraSmall: 12
                    ]
                ]
            ]
        }
        
        var preferredContentSizeCategory = UIContentSizeCategoryMedium
        if #available(iOSApplicationExtension 10.0, *) {
            preferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        }
        let size = Static.fontSizeTable[fontFamily]?[style]?[preferredContentSizeCategory] ?? 21

        switch fontFamily {
        case .Georgia:
            return UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: size), size: 0)
        case .SystemBlack:
            return UIFont.systemFontOfSize(size, weight: UIFontWeightBlack)
        case .SystemBold:
            return UIFont.boldSystemFontOfSize(size)
        case .System:
            assert(false, "Should never reach this point. System font is guarded against at beginning of method.")
            return nil
        }
    }
}

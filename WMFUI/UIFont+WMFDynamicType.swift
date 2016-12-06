import UIKit

extension UIFont {
    
    class func preferredGeorgiaFont(forTextStyle style: String, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont? {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var fontSizeTable: [String: [String: CGFloat]] = [:]
        }
        
        dispatch_once(&Static.onceToken) {
            Static.fontSizeTable = [
                UIFontTextStyleTitle2: [
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
                ]
            ]
        }
        
        var preferredContentSizeCategory = UIContentSizeCategoryMedium
        if #available(iOSApplicationExtension 10.0, *) {
            preferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        }
        let size = Static.fontSizeTable[style]?[preferredContentSizeCategory] ?? 21
        let descriptor = UIFontDescriptor(name: "Georgia", size: size)
        return UIFont(descriptor: descriptor, size: 0)
    }
}

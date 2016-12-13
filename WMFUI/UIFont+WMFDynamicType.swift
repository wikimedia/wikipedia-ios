import UIKit

@objc public enum WMFFontFamily: Int {
    case system
    case systemBlack
    case systemBold
    case georgia
}

public extension UIFont {

    public class func wmf_preferredFontForFontFamily(_ fontFamily: WMFFontFamily, withTextStyle style: String) -> UIFont? {
        return UIFont.wmf_preferredFontForFontFamily(fontFamily, withTextStyle: style, compatibleWithTraitCollection: UIScreen.main.traitCollection)
    }
    
    public class func wmf_preferredFontForFontFamily(_ fontFamily: WMFFontFamily, withTextStyle style: String, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont? {
        
        guard fontFamily != .system else {
            if #available(iOSApplicationExtension 10.0, *) {
                return UIFont.preferredFont(forTextStyle: UIFontTextStyle(rawValue: style), compatibleWith: traitCollection)
            } else {
                return UIFont.preferredFont(forTextStyle: UIFontTextStyle(rawValue: style))
            }
        }
        
        struct Static {
            static var onceToken: Int = 0
            static var fontSizeTable: [WMFFontFamily: [String: [String: CGFloat]]] = [:]
        }
        
        dispatch_once(&Static.onceToken) {
            Static.fontSizeTable = [
                .georgia:[
                    UIFontTextStyle.title2.rawValue: [
                        UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue: 28,
                        UIContentSizeCategory.accessibilityExtraExtraLarge.rawValue: 28,
                        UIContentSizeCategory.accessibilityExtraLarge.rawValue: 28,
                        UIContentSizeCategory.accessibilityLarge.rawValue: 28,
                        UIContentSizeCategory.accessibilityMedium.rawValue: 28,
                        UIContentSizeCategory.extraExtraExtraLarge.rawValue: 26,
                        UIContentSizeCategory.extraExtraLarge: 24,
                        UIContentSizeCategory.extraLarge: 22,
                        UIContentSizeCategory.large: 21,
                        UIContentSizeCategory.medium: 20,
                        UIContentSizeCategory.small: 19,
                        UIContentSizeCategory.extraSmall: 18
                    ],
                    UIFontTextStyle.title3: [
                        UIContentSizeCategory.accessibilityExtraExtraExtraLarge: 24,
                        UIContentSizeCategory.accessibilityExtraExtraLarge: 24,
                        UIContentSizeCategory.accessibilityExtraLarge: 24,
                        UIContentSizeCategory.accessibilityLarge: 24,
                        UIContentSizeCategory.accessibilityMedium: 24,
                        UIContentSizeCategory.extraExtraExtraLarge: 22,
                        UIContentSizeCategory.extraExtraLarge: 20,
                        UIContentSizeCategory.extraLarge: 19,
                        UIContentSizeCategory.large: 18,
                        UIContentSizeCategory.medium: 17,
                        UIContentSizeCategory.small: 16,
                        UIContentSizeCategory.extraSmall: 15
                    ]
                ],
                .systemBlack: [
                    UIFontTextStyle.title1: [
                        UIContentSizeCategory.accessibilityExtraExtraExtraLarge: 38,
                        UIContentSizeCategory.accessibilityExtraExtraLarge: 38,
                        UIContentSizeCategory.accessibilityExtraLarge: 38,
                        UIContentSizeCategory.accessibilityLarge: 38,
                        UIContentSizeCategory.accessibilityMedium: 38,
                        UIContentSizeCategory.extraExtraExtraLarge: 37,
                        UIContentSizeCategory.extraExtraLarge: 36,
                        UIContentSizeCategory.extraLarge: 35,
                        UIContentSizeCategory.large: 34,
                        UIContentSizeCategory.medium: 33,
                        UIContentSizeCategory.small: 32,
                        UIContentSizeCategory.extraSmall: 31
                    ]
                ],
                .systemBold: [
                    UIFontTextStyle.subheadline: [
                        UIContentSizeCategory.accessibilityExtraExtraExtraLarge: 21,
                        UIContentSizeCategory.accessibilityExtraExtraLarge: 21,
                        UIContentSizeCategory.accessibilityExtraLarge: 21,
                        UIContentSizeCategory.accessibilityLarge: 21,
                        UIContentSizeCategory.accessibilityMedium: 21,
                        UIContentSizeCategory.extraExtraExtraLarge: 21,
                        UIContentSizeCategory.extraExtraLarge: 19,
                        UIContentSizeCategory.extraLarge: 17,
                        UIContentSizeCategory.large: 15,
                        UIContentSizeCategory.medium: 14,
                        UIContentSizeCategory.small: 13,
                        UIContentSizeCategory.extraSmall: 12
                    ],
                    UIFontTextStyle.footnote: [
                        UIContentSizeCategory.accessibilityExtraExtraExtraLarge: 19,
                        UIContentSizeCategory.accessibilityExtraExtraLarge: 19,
                        UIContentSizeCategory.accessibilityExtraLarge: 19,
                        UIContentSizeCategory.accessibilityLarge: 19,
                        UIContentSizeCategory.accessibilityMedium: 19,
                        UIContentSizeCategory.extraExtraExtraLarge: 19,
                        UIContentSizeCategory.extraExtraLarge: 17,
                        UIContentSizeCategory.extraLarge: 15,
                        UIContentSizeCategory.large: 13,
                        UIContentSizeCategory.medium: 12,
                        UIContentSizeCategory.small: 12,
                        UIContentSizeCategory.extraSmall: 12
                    ],
                    UIFontTextStyle.body: [
                        UIContentSizeCategory.accessibilityExtraExtraExtraLarge: 53,
                        UIContentSizeCategory.accessibilityExtraExtraLarge: 47,
                        UIContentSizeCategory.accessibilityExtraLarge: 40,
                        UIContentSizeCategory.accessibilityLarge: 33,
                        UIContentSizeCategory.accessibilityMedium: 28,
                        UIContentSizeCategory.extraExtraExtraLarge: 23,
                        UIContentSizeCategory.extraExtraLarge: 21,
                        UIContentSizeCategory.extraLarge: 19,
                        UIContentSizeCategory.large: 17,
                        UIContentSizeCategory.medium: 16,
                        UIContentSizeCategory.small: 15,
                        UIContentSizeCategory.extraSmall: 14
                    ]
                ]
            ]
        }
        
        var preferredContentSizeCategory = UIContentSizeCategory.medium
        if #available(iOSApplicationExtension 10.0, *) {
            preferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        }
        let size = Static.fontSizeTable[fontFamily]?[style]?[preferredContentSizeCategory] ?? 21

        switch fontFamily {
        case .georgia:
            return UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: size), size: 0)
        case .systemBlack:
            return UIFont.systemFont(ofSize: size, weight: UIFontWeightBlack)
        case .systemBold:
            return UIFont.boldSystemFont(ofSize: size)
        case .system:
            assert(false, "Should never reach this point. System font is guarded against at beginning of method.")
            return nil
        }
    }
}

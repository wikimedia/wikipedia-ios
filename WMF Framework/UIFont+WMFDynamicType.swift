import UIKit

@objc public enum WMFFontFamily: Int {
    case system
    case systemBlack
    case systemMedium
    case systemBold
    case georgia
}

let fontSizeTable: [WMFFontFamily:[UIFontTextStyle:[UIContentSizeCategory:CGFloat]]] = {
    return [
        .georgia:[
            UIFontTextStyle.title1: [
                .accessibilityExtraExtraExtraLarge: 28,
                .accessibilityExtraExtraLarge: 28,
                .accessibilityExtraLarge: 28,
                .accessibilityLarge: 28,
                .accessibilityMedium: 28,
                .extraExtraExtraLarge: 26,
                .extraExtraLarge: 24,
                .extraLarge: 22,
                .large: 21,
                .medium: 20,
                .small: 19,
                .extraSmall: 18
            ],
            UIFontTextStyle.title2: [
                .accessibilityExtraExtraExtraLarge: 24,
                .accessibilityExtraExtraLarge: 24,
                .accessibilityExtraLarge: 24,
                .accessibilityLarge: 24,
                .accessibilityMedium: 24,
                .extraExtraExtraLarge: 22,
                .extraExtraLarge: 20,
                .extraLarge: 19,
                .large: 18,
                .medium: 17,
                .small: 16,
                .extraSmall: 15
            ],
            UIFontTextStyle.title3: [
                .accessibilityExtraExtraExtraLarge: 23,
                .accessibilityExtraExtraLarge: 23,
                .accessibilityExtraLarge: 23,
                .accessibilityLarge: 23,
                .accessibilityMedium: 23,
                .extraExtraExtraLarge: 21,
                .extraExtraLarge: 19,
                .extraLarge: 18,
                .large: 17,
                .medium: 16,
                .small: 15,
                .extraSmall: 14
            ]
        ],
        .systemBlack: [
            UIFontTextStyle.title1: [
                .accessibilityExtraExtraExtraLarge: 38,
                .accessibilityExtraExtraLarge: 38,
                .accessibilityExtraLarge: 38,
                .accessibilityLarge: 38,
                .accessibilityMedium: 38,
                .extraExtraExtraLarge: 37,
                .extraExtraLarge: 36,
                .extraLarge: 35,
                .large: 34,
                .medium: 33,
                .small: 32,
                .extraSmall: 31
            ]
        ],
        .systemBold: [
            UIFontTextStyle.subheadline: [
                .accessibilityExtraExtraExtraLarge: 21,
                .accessibilityExtraExtraLarge: 21,
                .accessibilityExtraLarge: 21,
                .accessibilityLarge: 21,
                .accessibilityMedium: 21,
                .extraExtraExtraLarge: 21,
                .extraExtraLarge: 19,
                .extraLarge: 17,
                .large: 15,
                .medium: 14,
                .small: 13,
                .extraSmall: 12
            ],
            UIFontTextStyle.footnote: [
                .accessibilityExtraExtraExtraLarge: 19,
                .accessibilityExtraExtraLarge: 19,
                .accessibilityExtraLarge: 19,
                .accessibilityLarge: 19,
                .accessibilityMedium: 19,
                .extraExtraExtraLarge: 19,
                .extraExtraLarge: 17,
                .extraLarge: 15,
                .large: 13,
                .medium: 12,
                .small: 12,
                .extraSmall: 12
            ],
            UIFontTextStyle.body: [
                .accessibilityExtraExtraExtraLarge: 53,
                .accessibilityExtraExtraLarge: 47,
                .accessibilityExtraLarge: 40,
                .accessibilityLarge: 33,
                .accessibilityMedium: 28,
                .extraExtraExtraLarge: 23,
                .extraExtraLarge: 21,
                .extraLarge: 19,
                .large: 17,
                .medium: 16,
                .small: 15,
                .extraSmall: 14
            ]
        ],
        .systemMedium: [
            UIFontTextStyle.subheadline: [ // Save for later button
                .accessibilityExtraExtraExtraLarge: 21,
                .accessibilityExtraExtraLarge: 21,
                .accessibilityExtraLarge: 21,
                .accessibilityLarge: 21,
                .accessibilityMedium: 21,
                .extraExtraExtraLarge: 21,
                .extraExtraLarge: 19,
                .extraLarge: 17,
                .large: 15,
                .medium: 14,
                .small: 13,
                .extraSmall: 12
            ]
        ]
    ]
}()

public extension UIFont {

    public class func wmf_preferredFontForFontFamily(_ fontFamily: WMFFontFamily, withTextStyle style: UIFontTextStyle) -> UIFont? {
        return UIFont.wmf_preferredFontForFontFamily(fontFamily, withTextStyle: style, compatibleWithTraitCollection: UIScreen.main.traitCollection)
    }
    
    public class func wmf_preferredFontForFontFamily(_ fontFamily: WMFFontFamily, withTextStyle style: UIFontTextStyle, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont? {
        
        guard fontFamily != .system else {
            if #available(iOSApplicationExtension 10.0, *) {
                return UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
            } else {
                return UIFont.preferredFont(forTextStyle: style)
            }
        }
        
        
        var preferredContentSizeCategory = UIContentSizeCategory.medium
        if #available(iOSApplicationExtension 10.0, *) {
            preferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        }
        
        let familyTable: [UIFontTextStyle:[UIContentSizeCategory:CGFloat]]? = fontSizeTable[fontFamily]
        let styleTable: [UIContentSizeCategory:CGFloat]? = familyTable?[style]
        let size: CGFloat = styleTable?[preferredContentSizeCategory] ?? 21

        switch fontFamily {
        case .georgia:
            return UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: size), size: 0)
        case .systemBlack:
            return UIFont.systemFont(ofSize: size, weight: UIFontWeightBlack)
        case .systemMedium:
            return UIFont.systemFont(ofSize: size, weight: UIFontWeightMedium)
        case .systemBold:
            return UIFont.boldSystemFont(ofSize: size)
        case .system:
            assertionFailure("Should never reach this point. System font is guarded against at beginning of method.")
            return nil
        }
    }
}

import UIKit

@objc public enum WMFFontFamily: Int {
    case system
    case systemBlack
    case systemMedium
    case systemBold
    case systemHeavy
    case systemItalic
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
            ],
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
            ]
        ],
        .systemHeavy: [
            UIFontTextStyle.headline: [
                .accessibilityExtraExtraExtraLarge: 43,
                .accessibilityExtraExtraLarge: 43,
                .accessibilityExtraLarge: 43,
                .accessibilityLarge: 43,
                .accessibilityMedium: 43,
                .extraExtraExtraLarge: 43,
                .extraExtraLarge: 42,
                .extraLarge: 41,
                .large: 40,
                .medium: 39,
                .small: 38,
                .extraSmall: 37
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
                .accessibilityExtraExtraExtraLarge: 20,
                .accessibilityExtraExtraLarge: 20,
                .accessibilityExtraLarge: 20,
                .accessibilityLarge: 20,
                .accessibilityMedium: 20,
                .extraExtraExtraLarge: 20,
                .extraExtraLarge: 18,
                .extraLarge: 16,
                .large: 14,
                .medium: 13,
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
        .systemItalic: [
            UIFontTextStyle.caption2: [
                .accessibilityExtraExtraExtraLarge: 20,
                .accessibilityExtraExtraLarge: 20,
                .accessibilityExtraLarge: 20,
                .accessibilityLarge: 20,
                .accessibilityMedium: 20,
                .extraExtraExtraLarge: 20,
                .extraExtraLarge: 18,
                .extraLarge: 16,
                .large: 14,
                .medium: 13,
                .small: 12,
                .extraSmall: 12
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
            ],
            UIFontTextStyle.headline: [ // Welcome screens headline
                .accessibilityExtraExtraExtraLarge: 39,
                .accessibilityExtraExtraLarge: 39,
                .accessibilityExtraLarge: 39,
                .accessibilityLarge: 39,
                .accessibilityMedium: 39,
                .extraExtraExtraLarge: 39,
                .extraExtraLarge: 38,
                .extraLarge: 37,
                .large: 36,
                .medium: 35,
                .small: 34,
                .extraSmall: 33
            ]
        ]
    ]
}()
public extension UITraitCollection {
    var wmf_preferredContentSizeCategory: UIContentSizeCategory {
        if #available(iOSApplicationExtension 10.0, *) {
            return preferredContentSizeCategory
        } else {
            return UIContentSizeCategory.medium
        }
    }
}

fileprivate var fontCache: [String: UIFont] = [:]

public extension UIFont {

    @objc public class func wmf_preferredFontForFontFamily(_ fontFamily: WMFFontFamily, withTextStyle style: UIFontTextStyle) -> UIFont? {
        return UIFont.wmf_preferredFontForFontFamily(fontFamily, withTextStyle: style, compatibleWithTraitCollection: UIScreen.main.traitCollection)
    }
    
    @objc public class func wmf_preferredFontForFontFamily(_ fontFamily: WMFFontFamily, withTextStyle style: UIFontTextStyle, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont? {
        
        guard fontFamily != .system else {
            if #available(iOSApplicationExtension 10.0, *) {
                return UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
            } else {
                return UIFont.preferredFont(forTextStyle: style)
            }
        }
        
        
        let preferredContentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        
        let familyTable: [UIFontTextStyle:[UIContentSizeCategory:CGFloat]]? = fontSizeTable[fontFamily]
        let styleTable: [UIContentSizeCategory:CGFloat]? = familyTable?[style]
        let size: CGFloat = styleTable?[preferredContentSizeCategory] ?? 21

        let cacheKey = "\(fontFamily.rawValue)-\(size)"
        if let font = fontCache[cacheKey] {
            return font
        }
        
        let font: UIFont
        switch fontFamily {
        case .georgia:
            font = UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: size), size: 0)
        case .systemBlack:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.black)
        case .systemMedium:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.medium)
        case .systemBold:
            font = UIFont.boldSystemFont(ofSize: size)
        case .systemHeavy:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.heavy)
        case .systemItalic:
            font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection).with(traits: [.traitItalic])
        case .system:
            assertionFailure("Should never reach this point. System font is guarded against at beginning of method.")
            font = UIFont.systemFont(ofSize: 17)
        }
        fontCache[cacheKey] = font
        return font
    }
    
    func with(traits: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}

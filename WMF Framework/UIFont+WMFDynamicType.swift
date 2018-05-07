import UIKit

@objc public enum WMFFontFamily: Int {
    case system
    case systemBlack
    case systemMedium
    case systemSemiBold
    case systemBold
    case systemHeavy
    case systemItalic
    case systemSemiBoldItalic
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
            return UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
        }
        
        let preferredContentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        
        let familyTable: [UIFontTextStyle:[UIContentSizeCategory:CGFloat]]? = fontSizeTable[fontFamily]
        let styleTable: [UIContentSizeCategory:CGFloat]? = familyTable?[style]
        let size: CGFloat = styleTable?[preferredContentSizeCategory] ?? UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection).pointSize

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
        case .systemItalic:
            font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection).with(traits: [.traitItalic])
        case .systemSemiBold:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.semibold)
        case .systemSemiBoldItalic:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.semibold).with(traits: [.traitItalic])
        case .systemBold:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.bold)
        case .systemHeavy:
            font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.heavy)
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

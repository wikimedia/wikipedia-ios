import UIKit

@objc(WMFFontFamily) public enum FontFamily: Int {
    case system
    case georgia
}

@objc (WMFDynamicTextStyle) public class DynamicTextStyle: NSObject {
    @objc public static let subheadline = DynamicTextStyle(.system, .subheadline)
    @objc public static let semiboldSubheadline = DynamicTextStyle(.system, .subheadline, .semibold)
    public static let mediumSubheadline = DynamicTextStyle(.system, .subheadline, .medium)
    public static let boldSubheadline = DynamicTextStyle(.system, .subheadline, .bold)
    public static let italicSubheadline = DynamicTextStyle(.system, .subheadline, .regular,  [UIFontDescriptor.SymbolicTraits.traitItalic])
    
    public static let headline = DynamicTextStyle(.system, .headline)
    public static let mediumHeadline = DynamicTextStyle(.system, .headline, .medium)
    public static let semiboldHeadline = DynamicTextStyle(.system, .headline, .semibold)
    public static let boldHeadline = DynamicTextStyle(.system, .headline, .bold)
    public static let heavyHeadline = DynamicTextStyle(.system, .headline, .heavy)

    public static let footnote = DynamicTextStyle(.system, .footnote)
    public static let mediumFootnote = DynamicTextStyle(.system, .footnote, .medium)
    @objc public static let semiboldFootnote = DynamicTextStyle(.system, .footnote, .semibold)
    public static let italicFootnote = DynamicTextStyle(.system, .footnote, .regular,  [UIFontDescriptor.SymbolicTraits.traitItalic])
    public static let boldFootnote = DynamicTextStyle(.system, .footnote, .bold)

    public static let boldTitle1 = DynamicTextStyle(.system, .title1, .bold)
    public static let mediumTitle1 = DynamicTextStyle(.system, .title1, .medium)
    public static let heavyTitle1 = DynamicTextStyle(.system, .title1, .heavy)

    public static let boldTitle2 = DynamicTextStyle(.system, .title2, .bold)
    public static let semiboldTitle3 = DynamicTextStyle(.system, .title3, .bold)

    public static let callout = DynamicTextStyle(.system, .callout)
    public static let semiboldCallout = DynamicTextStyle(.system, .callout, .semibold)
    public static let boldCallout = DynamicTextStyle(.system, .callout, .bold)
    public static let italicCallout = DynamicTextStyle(.system, .callout, .regular,  [UIFontDescriptor.SymbolicTraits.traitItalic])
    
    public static let title2 = DynamicTextStyle(.system, .title2)
    public static let title3 = DynamicTextStyle(.system, .title3)
    
    public static let body = DynamicTextStyle(.system, .body)
    @objc  public static let semiboldBody = DynamicTextStyle(.system, .body, .semibold)
    public static let italicBody = DynamicTextStyle(.system, .body, .regular,  [UIFontDescriptor.SymbolicTraits.traitItalic])

    public static let caption1 = DynamicTextStyle(.system, .caption1)
    public static let mediumCaption1 = DynamicTextStyle(.system, .caption1, .medium)
    public static let caption2 = DynamicTextStyle(.system, .caption2)
    public static let semiboldCaption2 = DynamicTextStyle(.system, .caption2, .semibold)
    public static let italicCaption2 = DynamicTextStyle(.system, .caption2, .regular, [UIFontDescriptor.SymbolicTraits.traitItalic])
    public static let italicCaption1 = DynamicTextStyle(.system, .caption1, .regular, [UIFontDescriptor.SymbolicTraits.traitItalic])

    public static let georgiaTitle3 = DynamicTextStyle(.georgia, .title3)

    let family: FontFamily
    let style: UIFont.TextStyle
    let weight: UIFont.Weight
    let traits: UIFontDescriptor.SymbolicTraits
    
    init(_ family: FontFamily = .system, _ style: UIFont.TextStyle, _ weight: UIFont.Weight = .regular, _ traits: UIFontDescriptor.SymbolicTraits = []) {
        self.family = family
        self.weight = weight
        self.traits = traits
        self.style = style
    }
    
    func with(weight: UIFont.Weight) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
    
    func with(traits: UIFontDescriptor.SymbolicTraits) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
    
    func with(weight: UIFont.Weight, traits: UIFontDescriptor.SymbolicTraits) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
}

public extension UITraitCollection {
    var wmf_preferredContentSizeCategory: UIContentSizeCategory {
         return preferredContentSizeCategory
    }
}

fileprivate var fontCache: [String: UIFont] = [:]

public extension UIFont {

    @objc(wmf_fontForDynamicTextStyle:) class func wmf_font(_ dynamicTextStyle: DynamicTextStyle) -> UIFont {
        return UIFont.wmf_font(dynamicTextStyle, compatibleWithTraitCollection: UITraitCollection(preferredContentSizeCategory: .large))
    }
    
    @objc(wmf_fontForDynamicTextStyle:compatibleWithTraitCollection:) class func wmf_font(_ dynamicTextStyle: DynamicTextStyle, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont {
        let fontFamily = dynamicTextStyle.family
        let weight = dynamicTextStyle.weight
        let traits = dynamicTextStyle.traits
        let style = dynamicTextStyle.style
        guard fontFamily != .system || weight != .regular || traits != [] else {
            return UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
        }
        
        let cacheKey = "\(fontFamily.rawValue)-\(weight.rawValue)-\(traits.rawValue)-\(style.rawValue)-\(traitCollection.preferredContentSizeCategory.rawValue)"
        if let font = fontCache[cacheKey] {
            return font
        }
        
        let size: CGFloat = UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection).pointSize

        var font: UIFont
        switch fontFamily {
        case .georgia:
            // using the standard .with(traits: doesn't seem to work for georgia
            let isBold = weight > UIFont.Weight.regular
            let isItalic = traits.contains(.traitItalic)
            if isBold && isItalic {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia-BoldItalic", size: size), size: 0)
            } else if isBold {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia-Bold", size: size), size: 0)
            } else if isItalic {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia-Italic", size: size), size: 0)
            } else {
                font = UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: size), size: 0)
            }
        case .system:
            font = weight != .regular ? UIFont.systemFont(ofSize: size, weight: weight) : UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
            if traits != [] {
                font = font.with(traits: traits)
            }
        }
        fontCache[cacheKey] = font
        return font
    }
    
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}

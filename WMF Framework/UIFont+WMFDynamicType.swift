import UIKit

@objc(WMFFontFamily) public enum FontFamily: Int {
    case system
    case georgia
}

@objc (WMFDynamicTextStyle) public class DynamicTextStyle: NSObject {
    @objc public static let subheadline = DynamicTextStyle(.system, .subheadline)
    @objc public static let semiboldSubheadline = DynamicTextStyle(.system, .subheadline, .semibold)
    public static let mediumSubheadline = DynamicTextStyle(.system, .subheadline, .medium)
    
    public static let headline = DynamicTextStyle(.system, .headline)
    public static let semiboldHeadline = DynamicTextStyle(.system, .headline, .semibold)
    public static let heavyHeadline = DynamicTextStyle(.system, .headline, .heavy)

    public static let footnote = DynamicTextStyle(.system, .footnote)
    public static let mediumFootnote = DynamicTextStyle(.system, .footnote, .medium)
    @objc public static let semiboldFootnote = DynamicTextStyle(.system, .footnote, .semibold)

    public static let boldTitle1 = DynamicTextStyle(.system, .title1, .bold)

    public static let boldTitle2 = DynamicTextStyle(.system, .title2, .bold)
    
    public static let title3 = DynamicTextStyle(.system, .title3)
    
    public static let body = DynamicTextStyle(.system, .body)
    public static let semiboldBody = DynamicTextStyle(.system, .body, .semibold)
    
    public static let caption1 = DynamicTextStyle(.system, .caption1)
    public static let caption2 = DynamicTextStyle(.system, .caption2)
    public static let semiboldCaption2 = DynamicTextStyle(.system, .caption2, .semibold)
    public static let italicCaption2 = DynamicTextStyle(.system, .caption2, .regular, [.traitItalic])

    public static let georgiaTitle3 = DynamicTextStyle(.georgia, .title3)

    let family: FontFamily
    let style: UIFontTextStyle
    let weight: UIFont.Weight
    let traits: UIFontDescriptorSymbolicTraits
    
    init(_ family: FontFamily = .system, _ style: UIFontTextStyle, _ weight: UIFont.Weight = .regular, _ traits: UIFontDescriptorSymbolicTraits = []) {
        self.family = family
        self.weight = weight
        self.traits = traits
        self.style = style
    }
    
    func with(weight: UIFont.Weight) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
    
    func with(traits: UIFontDescriptorSymbolicTraits) -> DynamicTextStyle {
        return DynamicTextStyle(family, style, weight, traits)
    }
    
    func with(weight: UIFont.Weight, traits: UIFontDescriptorSymbolicTraits) -> DynamicTextStyle {
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

    @objc(wmf_fontForDynamicTextStyle:) public class func wmf_font(_ dynamicTextStyle: DynamicTextStyle) -> UIFont {
        return UIFont.wmf_font(dynamicTextStyle, compatibleWithTraitCollection: UIScreen.main.traitCollection)
    }
    
    @objc(wmf_fontForDynamicTextStyle:compatibleWithTraitCollection:) public class func wmf_font(_ dynamicTextStyle: DynamicTextStyle, compatibleWithTraitCollection traitCollection: UITraitCollection) -> UIFont {
        let fontFamily = dynamicTextStyle.family
        let weight = dynamicTextStyle.weight
        let traits = dynamicTextStyle.traits
        let style = dynamicTextStyle.style
        guard fontFamily != .system || weight != .regular || traits != [] else {
            return UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection)
        }
                
        let size: CGFloat = UIFont.preferredFont(forTextStyle: style, compatibleWith: traitCollection).pointSize

        let cacheKey = "\(fontFamily.rawValue)-\(weight.rawValue)-\(traits.rawValue)-\(size)"
        if let font = fontCache[cacheKey] {
            return font
        }
        
        
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
    
    func with(traits: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}

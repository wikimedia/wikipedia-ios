import Components

 @objc public class WKFontWrapper: NSObject {
     @objc(fontFor:compatibleWithTraitCollection:) public static func font(for fontType: WMFFonts, compatibleWith traitCollection: UITraitCollection) -> UIFont {
        switch fontType {
        case .boldCallout:
            WKFont.for(.boldCallout, compatibleWith: traitCollection)
        case .callout:
            WKFont.for(.callout, compatibleWith: traitCollection)
        case .caption1:
            WKFont.for(.caption1, compatibleWith: traitCollection)
        case .subheadline:
            WKFont.for(.subheadline, compatibleWith: traitCollection)
        case .title1:
            WKFont.for(.title1, compatibleWith: traitCollection)
        }
    }
 }


/// WMFFonts is the equivalent of the `WKFont` enum in components.
/// This enum can be called directly from the Objective-C classes, without having to  import Components into them
@objc public enum WMFFonts: Int {
    case boldCallout
    case callout
    case caption1
    case subheadline
    case title1
}

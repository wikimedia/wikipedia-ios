import WMFComponents

 @objc public class WMFFontWrapper: NSObject {
     @objc(fontFor:compatibleWithTraitCollection:) public static func font(for fontType: WMFFonts, compatibleWith traitCollection: UITraitCollection) -> UIFont {
        switch fontType {
        case .boldCallout:
            WMFFont.for(.boldCallout, compatibleWith: traitCollection)
        case .callout:
            WMFFont.for(.callout, compatibleWith: traitCollection)
        case .caption1:
            WMFFont.for(.caption1, compatibleWith: traitCollection)
        case .semiboldHeadline:
            WMFFont.for(.semiboldHeadline, compatibleWith: traitCollection)
        case .subheadline:
            WMFFont.for(.subheadline, compatibleWith: traitCollection)
        case .title1:
            WMFFont.for(.title1, compatibleWith: traitCollection)
        }
    }
 }


/// WMFFonts is the equivalent of the `WMFFont` enum in components.
/// This enum can be called directly from the Objective-C classes, without having to  import WMFComponents into them
@objc public enum WMFFonts: Int {
    case boldCallout
    case callout
    case caption1
    case semiboldHeadline
    case subheadline
    case title1
}

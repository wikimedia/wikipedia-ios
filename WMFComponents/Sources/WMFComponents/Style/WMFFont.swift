import UIKit
import SwiftUI

public enum WMFFont {

    case body
    case boldBody
    case boldCallout
    case boldCaption1
    case boldFootnote
    case boldGeorgiaTitle1
    case boldGeorgiaTitle3
    case boldHeadline
    case boldItalicCallout
    case boldItalicFootnote
    case boldItalicGeorgiaTitle1
    case boldItalicGeorgiaTitle3
    case boldItalicSubheadline
    case boldSubheadline
    case boldTitle1
    case boldTitle3
    case georgiaCallout
    case callout
    case caption1
    case caption2
    case caption2Semibold
    case editorHeading
    case editorSubheading1
    case editorSubheading2
    case editorSubheading3
    case editorSubheading4
    case footnote
    case georgiaTitle1
    case georgiaTitle3
    case headline
    case italicCallout
    case italicCaption1
    case italicFootnote
    case italicGeorgiaTitle1
    case italicGeorgiaTitle3
    case italicSubheadline
    case mediumFootnote
    case mediumSubheadline
    case semiboldHeadline
    case semiboldSubheadline
    case semiboldTitle3
    case semiboldCaption1
    case subheadline
    case title1
    case title2
    case title3
    case xxlTitleBold
    case helveticaLargeHeadline
    case helveticaBody
    case helveticaBodyBold
    case helveticaCaption1

    public static func `for`(_ font: WMFFont, compatibleWith traitCollection: UITraitCollection = WMFAppEnvironment.current.traitCollection) -> UIFont {

        switch font {
        case .body:
            return UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        case .boldBody:
            let base = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        case .boldCallout:
            let base = UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .callout).scaledFont(for: font)

        case .boldCaption1:
            let base = UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)
            let bold = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: bold)
        case .boldFootnote:
            let base = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font)

        case .boldGeorgiaTitle1:
            let baseFont = WMFFont.for(.georgiaTitle1, compatibleWith: traitCollection)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitBold]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            return baseFont

        case .boldGeorgiaTitle3:
            let baseFont = WMFFont.for(.georgiaTitle3, compatibleWith: traitCollection)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitBold]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            return baseFont

        case .boldHeadline:
            let base = UIFont.preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
            let bold = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: bold)

        case .boldItalicCallout:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout, compatibleWith: traitCollection).withSymbolicTraits([.traitBold, .traitItalic]) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldItalicFootnote:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote, compatibleWith: traitCollection).withSymbolicTraits([.traitBold, .traitItalic]) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldItalicGeorgiaTitle1:
            let baseFont = WMFFont.for(.georgiaTitle1, compatibleWith: traitCollection)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitItalic, .traitBold]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            return baseFont

        case .boldItalicGeorgiaTitle3:
            let baseFont = WMFFont.for(.georgiaTitle3, compatibleWith: traitCollection)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitItalic, .traitBold]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            return baseFont

        case .boldItalicSubheadline:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline, compatibleWith: traitCollection).withSymbolicTraits([.traitBold, .traitItalic]) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldSubheadline:
            let base = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)

        case .boldTitle1:
            let base = UIFont.preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)

        case .boldTitle3:
            let base = UIFont.preferredFont(forTextStyle: .title3, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .bold)
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: font)

        case .georgiaCallout:
            return UIFontMetrics(forTextStyle: .callout).scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: 16), size: 0), compatibleWith: traitCollection)

        case .callout:
            let base = UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .regular)
            return UIFontMetrics(forTextStyle: .callout).scaledFont(for: font)

        case .caption1:
            return UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)
            
        case .caption2:
            return UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: traitCollection)
            
        case .caption2Semibold:
            let base = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
            return UIFontMetrics(forTextStyle: .caption2).scaledFont(for: font)

        case .editorHeading:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 28, weight: .semibold), compatibleWith: traitCollection)

        case .editorSubheading1:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 26, weight: .semibold), compatibleWith: traitCollection)

        case .editorSubheading2:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .semibold), compatibleWith: traitCollection)

        case .editorSubheading3:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold), compatibleWith: traitCollection)

        case .editorSubheading4:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold), compatibleWith: traitCollection)

        case .footnote:
            return UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)

        case .georgiaTitle1:
            return UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: 28), size: 0), compatibleWith: traitCollection)

        case .georgiaTitle3:
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: 20), size: 0), compatibleWith: traitCollection)

        case .headline:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 17, weight: .regular), compatibleWith: traitCollection)

        case .italicCallout:
            let base = UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
            let font = UIFont.italicSystemFont(ofSize: base.pointSize)
            return UIFontMetrics(forTextStyle: .callout).scaledFont(for: font)
        case .italicCaption1:
            let base = UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)
            let font = UIFont.italicSystemFont(ofSize: base.pointSize)
            return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: font)
        case .italicFootnote:
            let base = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)
            let font = UIFont.italicSystemFont(ofSize: base.pointSize)
            return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font)

        case .italicGeorgiaTitle1:
            let baseFont = WMFFont.for(.georgiaTitle1, compatibleWith: traitCollection)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitItalic]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            return baseFont

        case .italicGeorgiaTitle3:
            let baseFont = WMFFont.for(.georgiaTitle3, compatibleWith: traitCollection)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitItalic]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            return baseFont
        case .italicSubheadline:
            let base = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
            let font = UIFont.italicSystemFont(ofSize: base.pointSize)
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)

        case .mediumFootnote:
            let base = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .medium)
            return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font)

        case .mediumSubheadline:
            let base = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .medium)
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)

        case .semiboldHeadline:
            let base = UIFont.preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)

        case .semiboldSubheadline:
            let base = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)

        case .semiboldTitle3:
            let base = UIFont.preferredFont(forTextStyle: .title3, compatibleWith: traitCollection)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: font)
            
        case .semiboldCaption1:
            let base = UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)
            let bold = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
            return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: bold)

        case .subheadline:
            return UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)

        case .title1:
            return UIFont.preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)
            
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2, compatibleWith: traitCollection)

        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3, compatibleWith: traitCollection)
            
        case .xxlTitleBold:
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 40, weight: .bold), compatibleWith: traitCollection)
            
        case .helveticaLargeHeadline:
            return UIFontMetrics(forTextStyle: .headline)
                    .scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Helvetica-Bold", size: 17), size: 0), compatibleWith: traitCollection)

        case .helveticaBody:
            return UIFontMetrics(forTextStyle: .subheadline)
                    .scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Helvetica", size: 14), size: 0), compatibleWith: traitCollection)

        case .helveticaBodyBold:
            return UIFontMetrics(forTextStyle: .subheadline)
                   .scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Helvetica-Bold", size: 14), size: 0), compatibleWith: traitCollection)
        case .helveticaCaption1:
            return UIFontMetrics(forTextStyle: .caption1)
                   .scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "HelveticaNeue", size: 12), size: 0), compatibleWith: traitCollection)
        }
    }
}


/// SwiftUI-native font tokens mirroring WMFFOnt
public enum WMFSwiftUIFont {
    case mediumSubheadline
    case boldSubheadline
    case subheadline
    case caption1
    case callout

}

public extension WMFSwiftUIFont {
    static func font(_ style: WMFSwiftUIFont) -> Font {
        switch style {
        case .mediumSubheadline:
            return .system(.subheadline, design: .default).weight(.medium)
        case .boldSubheadline:
            return .system(.subheadline, design: .default).weight(.bold)
        case .subheadline:
            return .subheadline
        case .caption1:
            return .caption
        case .callout:
            return .callout
        }
    }
}

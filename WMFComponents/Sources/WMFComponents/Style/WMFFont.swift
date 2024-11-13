import UIKit
import SwiftUI

public enum WMFFont {

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
    case callout
    case caption1
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
    case subheadline
    case title1
    case title3
    case xxlTitleBold

    public static func `for`(_ font: WMFFont, compatibleWith traitCollection: UITraitCollection = WMFAppEnvironment.current.traitCollection) -> UIFont {

        switch font {
        case .boldCallout:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldCaption1:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldFootnote:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

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
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

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
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldTitle1:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .boldTitle3:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .callout:
            return UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)

        case .caption1:
            return UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)

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
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout, compatibleWith: traitCollection).withSymbolicTraits(.traitItalic) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .italicCaption1:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1, compatibleWith: traitCollection).withSymbolicTraits(.traitItalic) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .italicFootnote:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote, compatibleWith: traitCollection).withSymbolicTraits(.traitItalic) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

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
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline, compatibleWith: traitCollection).withSymbolicTraits(.traitItalic) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)

        case .mediumFootnote:
            return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 13, weight: .medium), compatibleWith: traitCollection)

        case .mediumSubheadline:
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .medium), compatibleWith: traitCollection)

        case .semiboldHeadline:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 17, weight: .semibold), compatibleWith: traitCollection)

        case .semiboldSubheadline:
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .semibold), compatibleWith: traitCollection)

        case .semiboldTitle3:
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold), compatibleWith: traitCollection)

        case .subheadline:
            return UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)

        case .title1:
            return UIFont.preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)

        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3, compatibleWith: traitCollection)
            
        case .xxlTitleBold:
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 40, weight: .bold), compatibleWith: traitCollection)

        }
    }

}

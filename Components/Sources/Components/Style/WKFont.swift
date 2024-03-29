import UIKit
import SwiftUI

public enum WKFont {

    case headline
    case title1
    case boldTitle1
    case boldTitle3
    case body
    case boldBody
    case italicsBody
    case boldItalicsBody
    case smallBody
    case smallItalicsBody
    case callout
    case boldCallout
    case italicsCallout
    case boldItalicsCallout
    case subheadline
    case boldSubheadline
    case mediumSubheadline
    case caption1
    case footnote
    case boldFootnote
    case editorHeading
    case editorSubheading1
    case editorSubheading2
    case editorSubheading3
    case editorSubheading4
    case georgiaHeadline
    case boldGeorgiaHeadline
    case italicsGeorgiaHeadline
    case boldItalicsGeorgiaHeadline

    public static func `for`(_ font: WKFont, compatibleWith traitCollection: UITraitCollection = WKAppEnvironment.current.traitCollection) -> UIFont {
        switch font {
        case .headline:
            return UIFont.preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
        case .title1:
            return UIFont.preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)
        case .boldTitle3:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .boldTitle1:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .body:
            return UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        case .boldBody:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .italicsBody:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body, compatibleWith: traitCollection).withSymbolicTraits(.traitItalic) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .boldItalicsBody:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body, compatibleWith: traitCollection).withSymbolicTraits(.traitBold.union(.traitItalic)) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .smallBody:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .regular))
        case .smallItalicsBody:
            let baseFont = WKFont.for(.smallBody)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitItalic]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            
            return baseFont
        case .callout:
            return UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        case .boldCallout:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .italicsCallout:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout, compatibleWith: traitCollection).withSymbolicTraits(.traitItalic) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .boldItalicsCallout:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout, compatibleWith: traitCollection).withSymbolicTraits([.traitBold, .traitItalic]) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .subheadline:
            return UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
        case .mediumSubheadline:
            return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .medium))
        case .boldSubheadline:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
        case .caption1:
            return UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)
        case .footnote:
            return UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)
        case .boldFootnote:
            guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote, compatibleWith: traitCollection).withSymbolicTraits(.traitBold) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: 0)
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
        case .georgiaHeadline:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont(descriptor: UIFontDescriptor(name: "Georgia", size: 27), size: 0), compatibleWith: traitCollection)
        case .boldGeorgiaHeadline:
            let baseFont = WKFont.for(.georgiaHeadline)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitBold]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            
            return baseFont
        case .italicsGeorgiaHeadline:
            let baseFont = WKFont.for(.georgiaHeadline)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitItalic]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            
            return baseFont
        case .boldItalicsGeorgiaHeadline:
            let baseFont = WKFont.for(.georgiaHeadline)
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
                return UIFont(descriptor: descriptor, size: 0)
            }
            
            return baseFont
        }
	}
}

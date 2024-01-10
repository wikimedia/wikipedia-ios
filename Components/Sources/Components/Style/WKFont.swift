import UIKit
import SwiftUI

public enum WKFont {

    case headline
    case title
    case boldTitle
    case body
    case boldBody
    case italicsBody
    case boldItalicsBody
    case smallBody
    case callout
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

    static func `for`(_ font: WKFont, compatibleWith traitCollection: UITraitCollection = WKAppEnvironment.current.traitCollection) -> UIFont {
        switch font {
        case .headline:
            return UIFont.preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
        case .title:
            return UIFont.preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)
        case .boldTitle:
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
        case .callout:
            return UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
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
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 28, weight: .semibold), maximumPointSize: 32, compatibleWith: traitCollection)
        case .editorSubheading1:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 26, weight: .semibold), compatibleWith: traitCollection)
        case .editorSubheading2:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .semibold), compatibleWith: traitCollection)
        case .editorSubheading3:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold), compatibleWith: traitCollection)
        case .editorSubheading4:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold), compatibleWith: traitCollection)
        }
        
	}
}

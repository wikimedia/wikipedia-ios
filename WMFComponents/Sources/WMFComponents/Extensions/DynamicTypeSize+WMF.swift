import SwiftUI

extension DynamicTypeSize {
    /// Trait collection carrying the SwiftUI environment's Dynamic Type size, for UIKit-based
    /// sizing (e.g. `WMFSFSymbolIcon.for(symbol:font:compatibleWith:)`) under a cap.
    var wmfTraitCollection: UITraitCollection {
        UITraitCollection(preferredContentSizeCategory: wmfContentSizeCategory)
    }

    /// UIKit equivalent of the SwiftUI environment value, so UIFontMetrics-based fonts can
    /// honor a view-level dynamicTypeSize cap.
    var wmfContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}

extension WMFFont {
    /// Resolves a font against the SwiftUI environment's Dynamic Type size instead of the app
    /// trait collection. Use in views under a `dynamicTypeSize` cap: WMFFont otherwise scales
    /// from the uncapped app trait collection and ignores the cap.
    static func `for`(_ font: WMFFont, sized dynamicTypeSize: DynamicTypeSize) -> UIFont {
        `for`(font, compatibleWith: UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.wmfContentSizeCategory))
    }
}

import SwiftUI

/// Caps content to a readable column on wide screens. Larger text sizes get a wider column, and the
/// accessibility sizes get the full width. The saved rows, the Discover card and the Discover list share it.
struct WMFReadableWidthModifier: ViewModifier {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let alignment: Alignment

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: Self.maximumWidth(for: dynamicTypeSize))
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    static func maximumWidth(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return 700
        case .xLarge, .xxLarge, .xxxLarge:
            return 800
        case .accessibility1, .accessibility2:
            return 900
        case .accessibility3, .accessibility4, .accessibility5:
            return .infinity
        @unknown default:
            return 700
        }
    }
}

extension View {
    /// Keeps the content inside the readable column and places the column with `alignment`.
    func readableWidth(alignment: Alignment = .center) -> some View {
        modifier(WMFReadableWidthModifier(alignment: alignment))
    }
}

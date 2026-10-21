import SwiftUI

private struct WMFDidScrollToTopKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable () -> Void)? = nil
}

extension EnvironmentValues {
    /// Called by a scroll view when it reaches its top. Screens that hide the navigation bar
    /// on swipe use it to show the bar again.
    var wmfDidScrollToTop: (@MainActor @Sendable () -> Void)? {
        get { self[WMFDidScrollToTopKey.self] }
        set { self[WMFDidScrollToTopKey.self] = newValue }
    }
}

private struct WMFScrollToTopReporting: ViewModifier {
    @Environment(\.wmfDidScrollToTop) private var didScrollToTop

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top < 5
            } action: { _, isAtTop in
                if isAtTop {
                    didScrollToTop?()
                }
            }
        } else {
            content
        }
    }
}

extension View {
    /// Reports to `wmfDidScrollToTop` when this scroll view reaches its top.
    func wmfReportsScrollToTop() -> some View {
        modifier(WMFScrollToTopReporting())
    }
}

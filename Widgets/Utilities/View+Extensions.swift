import SwiftUI

extension View {

    func readableShadow(intensity: Double = 0.80) -> some View {
        return self.shadow(color: Color.black.opacity(intensity), radius: 5, x:0, y: 0)
    }

    /// Adds an iOS-version dependent `List` background `Color`
    /// - Parameters:
    ///   - color: `Color` to use as background
    ///   - edges: safe area edges to ignore
    /// - Returns: a modified `View` with the desired background `Color` applied
    @ViewBuilder
    func listBackgroundColor(_ color: Color, ignoringSafeAreaEdges edges: Edge.Set = .all) -> some View {
        if #available(iOS 16, *) {
            self
                .scrollContentBackground(.hidden)
                .background(color).edgesIgnoringSafeArea(edges)
        } else {
            self.background(color).edgesIgnoringSafeArea(edges)
        }
    }

    /// Sets container background of the view to `Color.clear` if on iOS 17
    /// - Returns: a modified `View` with the iOS 17 container background modifier applied if needed
    @ViewBuilder
    func clearWidgetContainerBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color.clear
            }
        } else {
            self
        }
    }

}

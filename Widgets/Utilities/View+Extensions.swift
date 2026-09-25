import SwiftUI

extension View {

    func readableShadow(intensity: Double = 0.80) -> some View {
        return self.shadow(color: Color.black.opacity(intensity), radius: 5, x:0, y: 0)
    }

    /// Sets container background of the view to `Color.clear` if on iOS 17
    /// - Returns: a modified `View` with the iOS 17 container background modifier applied if needed
    @ViewBuilder
    func clearWidgetContainerBackground() -> some View {
        self.containerBackground(for: .widget) {
            Color.clear
        }
    }

}

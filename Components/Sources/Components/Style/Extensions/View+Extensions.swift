import SwiftUI

public extension View {
    /// Adds an iOS-version dependent `List` background `Color`
    /// - Parameters:
    ///   - color: `Color` to use as background
    ///   - edges: safe area edges to ignore
    /// - Returns: a modified `View` with the desired background `Color` applied
    @ViewBuilder
    func listBackgroundColor(_ color: Color) -> some View {
        if #available(iOS 16, *) {
            self
                .scrollContentBackground(.hidden)
                .background(color)
        } else {
            self.background(color)
        }
    }

	/// Adds custom section spacing if available on current iOS version
	/// - Parameter spacing: the amount of spacing to use
	/// - Returns: a modified `View` with the `List` `Section` spacing applied if possible
	@ViewBuilder
	func listCustomSectionSpacing(_ spacing: CGFloat) -> some View {
		if #available(iOS 17, *) {
			self.listSectionSpacing(.custom(spacing))
		} else {
			self
		}
	}
}

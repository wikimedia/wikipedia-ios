import SwiftUI

extension View {

	func readableShadow() -> some View {
		return self.shadow(color: Color.black.opacity(0.80), radius: 5, x:0, y: 0)
	}

}

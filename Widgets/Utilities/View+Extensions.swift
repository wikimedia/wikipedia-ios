import SwiftUI

extension View {

    func readableShadow(intensity: Double = 0.80) -> some View {
        return self.shadow(color: Color.black.opacity(intensity), radius: 5, x:0, y: 0)
    }

}

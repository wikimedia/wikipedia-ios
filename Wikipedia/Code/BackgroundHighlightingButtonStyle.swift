import Foundation
import SwiftUI

struct BackgroundHighlightingButtonStyle: ButtonStyle {

    @EnvironmentObject var observableTheme: ObservableTheme

    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(observableTheme.theme.colors.midBackground) : Color(observableTheme.theme.colors.paperBackground))
    }
}

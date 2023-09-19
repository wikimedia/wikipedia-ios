import SwiftUI

struct WKToggleView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    var theme: WKTheme {
        return appEnvironment.theme
    }
    
    let title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Toggle(isOn: $isSelected) {
            Text(title)
        }
        .foregroundColor(Color(theme.text))
        .toggleStyle(SwitchToggleStyle(tint: Color(theme.accent)))
    }
}

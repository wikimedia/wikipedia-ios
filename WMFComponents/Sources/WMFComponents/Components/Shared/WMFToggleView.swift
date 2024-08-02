import SwiftUI

struct WMFToggleView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
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

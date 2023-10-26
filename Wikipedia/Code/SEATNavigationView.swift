import SwiftUI
import Components

struct SEATNavigationView: View {
    
    @ObservedObject private var appEnvironment = WKAppEnvironment.current
    
    private var theme: WKTheme {
        appEnvironment.theme
    }
    
    var body: some View {
        NavigationView {
            SEATSelectionView()
        }
        .accentColor(Color(theme.text))
    }
}

// #Preview {
//    SEATNavigationView()
// }

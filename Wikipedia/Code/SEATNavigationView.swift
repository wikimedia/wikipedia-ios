import SwiftUI
import Components

struct SEATNavigationView: View {
    
    @ObservedObject private var appEnvironment = WKAppEnvironment.current
    
    private var theme: WKTheme {
        appEnvironment.theme
    }

    var onboardingModalAction: (() -> Void)?

    var body: some View {
        NavigationView {
            SEATSelectionView(onboardingModalAction: onboardingModalAction)
        }
        .accentColor(Color(theme.text))
    }
}

// #Preview {
//    SEATNavigationView()
// }

import SwiftUI

struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        WMFActivityTabLoggedOutView()
    }
}

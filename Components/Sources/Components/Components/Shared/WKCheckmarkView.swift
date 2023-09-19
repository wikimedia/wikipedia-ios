import SwiftUI

struct WKCheckmarkView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    var theme: WKTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        if let uiImage = WKSFSymbolIcon.for(symbol: .checkmark, font: .boldFootnote) {
            Image(uiImage: uiImage)
                .foregroundColor(Color(theme.link))
        }
    }
}

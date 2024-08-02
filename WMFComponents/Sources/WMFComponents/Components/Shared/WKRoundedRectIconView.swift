import SwiftUI

struct WKRoundedRectIconView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    var theme: WKTheme {
        return appEnvironment.theme
    }
    
    public struct Configuration {
        let icon: UIImage
        let imagePadding = 6
        let cornerRadius = 6
        let foregroundColor: KeyPath<WKTheme, UIColor>
        let backgroundColor: KeyPath<WKTheme, UIColor>
    }
    
    let configuration: Configuration

    var body: some View {
        Image(uiImage: configuration.icon)
            .padding(CGFloat(configuration.imagePadding))
            .foregroundColor(Color(theme[keyPath: configuration.foregroundColor]))
            .background(Color(theme[keyPath: configuration.backgroundColor]))
            .cornerRadius(CGFloat(configuration.cornerRadius))
    }
}

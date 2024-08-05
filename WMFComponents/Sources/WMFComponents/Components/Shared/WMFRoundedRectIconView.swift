import SwiftUI

struct WMFRoundedRectIconView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public struct Configuration {
        let icon: UIImage
        let imagePadding = 6
        let cornerRadius = 6
        let foregroundColor: KeyPath<WMFTheme, UIColor>
        let backgroundColor: KeyPath<WMFTheme, UIColor>
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

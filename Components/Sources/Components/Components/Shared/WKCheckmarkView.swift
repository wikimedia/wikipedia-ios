import SwiftUI

struct WKCheckmarkView: View {
    
    struct Configuration {
        
        enum Style {
            case checkbox
            case `default`
        }
        
        let style: Style
    }
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    let isSelected: Bool
    let configuration: Configuration
    
    var theme: WKTheme {
        return appEnvironment.theme
    }
    
    private var uiImage: UIImage? {
        switch configuration.style {
        case .checkbox:
            return isSelected ? WKSFSymbolIcon.for(symbol: .checkmarkSquareFill) : WKSFSymbolIcon.for(symbol: .square)
        case .`default`:
            return isSelected ? WKSFSymbolIcon.for(symbol: .checkmark, font: .boldFootnote) : nil
        }
    }
    
    private var foregroundColor: UIColor? {
        switch configuration.style {
        case .checkbox:
            return isSelected ? appEnvironment.theme.link : appEnvironment.theme.secondaryText
        case .`default`:
            return isSelected ? appEnvironment.theme.link : nil
        }
    }
    
    var body: some View {
        if let uiImage,
        let foregroundColor {
            Image(uiImage: uiImage)
                .foregroundColor(Color(foregroundColor))
        }
    }
}

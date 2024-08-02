import SwiftUI

struct WMFCheckmarkView: View {
    
    struct Configuration {
        
        enum Style {
            case checkbox
            case `default`
        }
        
        let style: Style
    }
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let isSelected: Bool
    let configuration: Configuration
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var uiImage: UIImage? {
        switch configuration.style {
        case .checkbox:
            return isSelected ? WMFSFSymbolIcon.for(symbol: .checkmarkSquareFill) : WMFSFSymbolIcon.for(symbol: .square)
        case .`default`:
            return isSelected ? WMFSFSymbolIcon.for(symbol: .checkmark, font: .boldFootnote) : nil
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

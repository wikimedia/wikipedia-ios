import SwiftUI

public struct WKSmallButton: View {
    
    public struct Configuration {
        public enum Style {
            case neutral
            case quiet
        }
        
        public let style: Style
        public let needsDisclosure: Bool
        
        public init(style: WKSmallButton.Configuration.Style, needsDisclosure: Bool = false) {
            self.style = style
            self.needsDisclosure = needsDisclosure
        }
    }

    @ObservedObject var appEnvironment = WKAppEnvironment.current

    let configuration: Configuration
    let title: String
    let action: (() -> Void)?
    
    public init(configuration: Configuration, title: String, action: (() -> Void)?) {
        self.configuration = configuration
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(Font(WKFont.for(.mediumSubheadline)))
                    .foregroundColor(Color(appEnvironment.theme.link))
                
                if configuration.needsDisclosure,
                let uiImage = WKSFSymbolIcon.for(symbol: .chevronForward, font: .mediumSubheadline) {
                    Image(uiImage: uiImage)
                        .foregroundColor(Color(appEnvironment.theme.link))
                }
            }
            .padding([.top, .bottom], 4)
            .padding([.leading, .trailing], 8)
            
        })
        .backgroundAndRadius(configuration: configuration, theme: appEnvironment.theme)
        
    }
}

private extension View {
    @ViewBuilder
    func backgroundAndRadius(configuration: WKSmallButton.Configuration, theme: WKTheme) -> some View {
        switch configuration.style {
        case .neutral:
            self
                .background(Color(theme.baseBackground))
                .cornerRadius(8)
        case .quiet:
            self
        }
    }
}

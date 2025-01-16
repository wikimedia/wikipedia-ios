import SwiftUI

public struct WMFSmallButton: View {
    
    public struct Configuration {
        public enum Style {
            case neutral
            case quiet
        }
        
        public let style: Style
        public let trailingIcon: UIImage?
        
        public init(style: WMFSmallButton.Configuration.Style, trailingIcon: UIImage? = nil) {
            self.style = style
            self.trailingIcon = trailingIcon
        }
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

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
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .foregroundColor(Color(appEnvironment.theme.link))
                
                if let trailingIcon = configuration.trailingIcon {
                    Image(uiImage: trailingIcon)
                        .foregroundColor(Color(appEnvironment.theme.link))
                }
            }
            .padding([.top, .bottom], 12)
            .padding([.leading, .trailing], 8)
            
        })
        .backgroundAndRadius(configuration: configuration, theme: appEnvironment.theme)
        
    }
}

private extension View {
    @ViewBuilder
    func backgroundAndRadius(configuration: WMFSmallButton.Configuration, theme: WMFTheme) -> some View {
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

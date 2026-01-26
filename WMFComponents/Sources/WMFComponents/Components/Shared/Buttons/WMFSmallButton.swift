import SwiftUI

public struct WMFSmallButton: View {
    
    public struct Configuration {
        public enum Style {
            case neutral
            case quiet
            case primary
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
    let image: UIImage?
    
    public init(configuration: Configuration, title: String, image: UIImage? = nil, action: (() -> Void)?) {
        self.configuration = configuration
        self.title = title
        self.action = action
        self.image = image
    }

    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            HStack(spacing: 4) {
                if let image = image {
                    Image(uiImage: image)
                        .foregroundColor(Color(configuration.style == .primary ? appEnvironment.theme.paperBackground : appEnvironment.theme.link))
                }
                Text(title)
                    .font(Font(WMFFont.for(.mediumSubheadline)))
                    .foregroundColor(Color(configuration.style == .primary ? appEnvironment.theme.paperBackground : appEnvironment.theme.link))
                
                if let trailingIcon = configuration.trailingIcon {
                    Image(uiImage: trailingIcon)
                        .foregroundColor(Color(configuration.style == .primary ? appEnvironment.theme.paperBackground : appEnvironment.theme.link))
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
    func backgroundAndRadius(configuration: WMFSmallButton.Configuration, theme: WMFTheme) -> some View {
        switch configuration.style {
        case .neutral:
            self
                .background(Color(theme.baseBackground))
                .cornerRadius(8)
        case .quiet:
            self
        case .primary:
            self
                .background(Color(theme.link))
                .cornerRadius(8)
        }
    }
}

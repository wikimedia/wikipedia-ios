import SwiftUI

public struct WKSmallButton: View {
    
    public enum Configuration {
        case neutral
        case quiet
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
            Text(title)
                .font(Font(WKFont.for(.mediumSubheadline)))
                .foregroundColor(Color(appEnvironment.theme.link))
                .padding([.top, .bottom], 4)
                .padding([.leading, .trailing], 8)
        })
        .backgroundAndRadius(configuration: configuration, theme: appEnvironment.theme)
        
    }
}

private extension View {
    @ViewBuilder
    func backgroundAndRadius(configuration: WKSmallButton.Configuration, theme: WKTheme) -> some View {
        switch configuration {
        case .neutral:
            self
                .background(Color(theme.baseBackground))
                .cornerRadius(8)
        case .quiet:
            self
        }
    }
}

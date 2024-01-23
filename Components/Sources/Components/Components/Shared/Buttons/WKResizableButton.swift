import SwiftUI

public struct WKResizableButton: View {
    
    public enum Configuration {
        case medium
        case small
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
    
    private var font: Font {
        switch configuration {
        case .medium:
            return Font(WKFont.for(.boldSubheadline))
        case .small:
            return Font(WKFont.for(.mediumSubheadline))
        }
    }
    
    private var paddingVertical: CGFloat {
        switch configuration {
        case .medium:
            return 12
        case .small:
            return 4
        }
    }
    
    private var paddingHorizontal: CGFloat {
        switch configuration {
        case .medium:
            return 12
        case .small:
            return 8
        }
    }

    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            Text(title)
                .font(font)
                .foregroundColor(Color(appEnvironment.theme.link))
                .padding([.top, .bottom], paddingVertical)
                .padding([.leading, .trailing], paddingHorizontal)
        })
        .background(Color(appEnvironment.theme.baseBackground))
        .cornerRadius(8)
    }
}

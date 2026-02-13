import SwiftUI

public struct WMFSmallSwiftUIMenuButton: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    public let configuration: WMFSmallMenuButton.Configuration
    public weak var menuButtonDelegate: WMFSmallMenuButtonDelegate?

    public init(configuration: WMFSmallMenuButton.Configuration, menuButtonDelegate: WMFSmallMenuButtonDelegate?) {
        self.configuration = configuration
        self.menuButtonDelegate = menuButtonDelegate
    }

    public var body: some View {
        Menu(content: {
            ForEach(configuration.menuItems) { menuItem in
                Button(action: {
                    if UIAccessibility.isVoiceOverRunning {
                        menuButtonDelegate?.wmfSwiftUIMenuButtonUserDidTapAccessibility(configuration: configuration, item: menuItem)
                    } else {
                        menuButtonDelegate?.wmfSwiftUIMenuButtonUserDidTap(configuration: configuration, item: menuItem)
                    }
                }) {
                    HStack {
                        Text(menuItem.title)
                        Spacer()
                        if let image = menuItem.image {
                            Image(uiImage: image)
                        }
                    }
                }
            }
        }, label: {
            HStack(spacing: 6) {
                if let image = configuration.image {
                    Image(uiImage: image)
                        .foregroundColor(Color(appEnvironment.theme.link))
                }
                if let title = configuration.title {
                    Text(title)
                        .lineLimit(1)
                        .font(Font(WMFFont.for(.boldFootnote)))
                }
            }
            .foregroundColor(Color(appEnvironment.theme.link))
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(Color(appEnvironment.theme.baseBackground))
            )
            .clipShape(Capsule())
        })
        .highPriorityGesture(TapGesture().onEnded {
            menuButtonDelegate?.wmfSwiftUIMenuButtonUserDidTap(configuration: configuration, item: nil)
        })
    }
}


import SwiftUI


struct WMFCloseButton: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let action: (() -> Void)?
    
    public init(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, action: (() -> Void)?) {
        self.appEnvironment = appEnvironment
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            if let closeIconName = WMFSFSymbolIcon.closeCircleFill.name {
                Image(systemName: closeIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color(uiColor: theme.link), Color(uiColor: theme.baseBackground))
            }
        })
    }
}

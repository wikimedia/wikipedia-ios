import SwiftUI

// Use for pure-SwiftUI close buttons when NOT embedded in a navigation toolbar. If a navigation toolbar is needed, lean on WMFNavigationBarConfiguring's configureNavigationBar with WMFNavigationBarCloseButtonConfig in the hosting controller.
public struct WMFLargeCloseButton: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public enum ImageType {
        case plainX
        case prominentCheck
    }

    let imageType: ImageType
    private let uiImage: UIImage
    let action: (() -> Void)?
    
    public init?(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, imageType: ImageType, action: (() -> Void)?) {
        
        switch imageType {
        case .plainX:
            guard let image = WMFSFSymbolIcon.for(symbol: .close, font: WMFFont.navigationBarCloseButtonFont) else {
                return nil
            }
            self.uiImage = image
        case .prominentCheck:
            guard let image = WMFSFSymbolIcon.for(symbol: .checkmark, font: WMFFont.navigationBarCloseButtonFont) else {
                return nil
            }
            self.uiImage = image
        }
        
        self.appEnvironment = appEnvironment
        self.imageType = imageType
        self.action = action
    }
    
    private var prominentCheckButton: some View {
        if #available(iOS 26.0, *) {
            return Button(action: {
                action?()
            }, label: {
                Image(uiImage: uiImage)
            })
            .frame(width: 44, height: 44)
            .tint(Color(WMFAppEnvironment.current.theme.navigationBarTintColor))
            .buttonStyle(.glassProminent)
        } else {
            return Button(action: {
                action?()
            }, label: {
                Image(uiImage: uiImage)
            })
            .frame(width: 44, height: 44)
            .tint(Color(WMFAppEnvironment.current.theme.navigationBarTintColor))
        }
    }
    
    private var plainXButton: some View {
        if #available(iOS 26.0, *) {
            return Button(action: {
                action?()
            }, label: {
                Image(uiImage: uiImage)
            })
            .frame(width: 44, height: 44)
            .glassEffect(.regular)
            .tint(Color(WMFAppEnvironment.current.theme.text))
        } else {
            return Button(action: {
                action?()
            }, label: {
                Image(uiImage: uiImage)
            })
            .frame(width: 44, height: 44)
            .tint(Color(WMFAppEnvironment.current.theme.text))
        }
    }
    
    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            switch imageType {
            case .plainX:
                plainXButton
            case .prominentCheck:
                prominentCheckButton
            }
        })
    }
}

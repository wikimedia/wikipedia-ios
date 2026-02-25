import SwiftUI

@objc public class WMFLargeCloseButtonConfig: NSObject {
    
    @objc public enum Alignment: Int {
        case leading
        case trailing
    }
    
    let imageType: WMFLargeCloseButtonImageType
    let target: Any
    let action: Selector
    let alignment: Alignment
    
    @objc public init(imageType: WMFLargeCloseButtonImageType, target: Any, action: Selector, alignment: Alignment) {
        self.imageType = imageType
        self.target = target
        self.action = action
        self.alignment = alignment
    }
}

@objc public enum WMFLargeCloseButtonImageType: Int {
    case plainX = 100
    case prominentCheck = 101

    var tag: Int { rawValue }

    var sfSymbol: WMFSFSymbolIcon {
        switch self {
        case .plainX: return .close
        case .prominentCheck: return .checkmark
        @unknown default: return .close
        }
    }

    func tintColor(theme: WMFTheme) -> UIColor {
        switch self {
        case .plainX: return theme.text
        case .prominentCheck: return theme.link
        }
    }

    func swiftUITintColor(theme: WMFTheme) -> Color {
        switch self {
        case .plainX: return Color(theme.text)
        case .prominentCheck: return Color(theme.navigationBarTintColor)
        }
    }
}

// MARK: UIKit - UIBarButtonItem

@objc public extension UIBarButtonItem {
    @objc static func closeNavigationBarButtonItem(
        config: WMFLargeCloseButtonConfig
    ) -> UIBarButtonItem {
        let theme = WMFAppEnvironment.current.theme
        let item: UIBarButtonItem

        switch config.imageType {
        case .plainX:
            let image = WMFSFSymbolIcon.for(symbol: .close, font: WMFFont.navigationBarCloseButtonFont)
            item = UIBarButtonItem(image: image, style: .plain, target: config.target, action: config.action)
            item.tintColor = theme.text

        case .prominentCheck:
            let image = WMFSFSymbolIcon.for(symbol: .checkmark, font: WMFFont.navigationBarCloseButtonFont)
            if #available(iOS 26.0, *) {
                item = UIBarButtonItem(image: image, style: .prominent, target: config.target, action: config.action)
            } else {
                item = UIBarButtonItem(image: image, style: .done, target: config.target, action: config.action)
            }
            item.tintColor = theme.link
        }

        item.tag = config.imageType.tag
        return item
    }
}

// MARK: UIKit - UIButton

@objc public extension UIButton {
    @objc static func closeNavigationButton(
        config: WMFLargeCloseButtonConfig
    ) -> UIButton {
        let theme = WMFAppEnvironment.current.theme
        let button = UIButton(type: .system)

        switch config.imageType {
        case .plainX:
            button.setImage(WMFSFSymbolIcon.for(symbol: .close, font: WMFFont.navigationBarCloseButtonFont), for: .normal)
            button.tintColor = theme.text
            
            if #available(iOS 26.0, *) {
                button.configuration = .glass()
            }

        case .prominentCheck:
            button.setImage(WMFSFSymbolIcon.for(symbol: .checkmark, font: WMFFont.navigationBarCloseButtonFont), for: .normal)
            button.tintColor = theme.link
            
            if #available(iOS 26.0, *) {
                button.configuration = .prominentGlass()
            }
        }

        button.tag = config.imageType.tag
        button.addTarget(config.target, action: config.action, for: .touchUpInside)
        return button
    }
}

// MARK: SwiftUI

// Use for pure-SwiftUI close buttons when NOT embedded in a navigation toolbar. If a navigation toolbar is needed, lean on UIBarButtonItem.closeNavigationBarButtonItem and WMFNavigationBarConfiguring's configureNavigationBar method.
public struct WMFLargeCloseButton: View {

    @ObservedObject var appEnvironment: WMFAppEnvironment

    var theme: WMFTheme { appEnvironment.theme }

    let imageType: WMFLargeCloseButtonImageType
    private let uiImage: UIImage
    let action: (() -> Void)?

    public init?(
        appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current,
        imageType: WMFLargeCloseButtonImageType,
        action: (() -> Void)?
    ) {
        guard let image = WMFSFSymbolIcon.for(symbol: imageType.sfSymbol, font: WMFFont.navigationBarCloseButtonFont) else {
            return nil
        }
        self.appEnvironment = appEnvironment
        self.imageType = imageType
        self.uiImage = image
        self.action = action
    }

    public var body: some View {
        switch imageType {
        case .plainX:
            plainXButton
        case .prominentCheck:
            prominentCheckButton
        @unknown default:
            plainXButton
        }
    }

    private var plainXButton: some View {
        let base = Button { action?() } label: {
            Image(uiImage: uiImage)
        }
        .frame(width: 44, height: 44)
        .tint(imageType.swiftUITintColor(theme: theme))

        if #available(iOS 26.0, *) {
            return base.glassEffect(.regular)
        } else {
            return base
        }
    }

    private var prominentCheckButton: some View {
        let base = Button { action?() } label: {
            Image(uiImage: uiImage)
        }
        .frame(width: 44, height: 44)
        .tint(imageType.swiftUITintColor(theme: theme))

        if #available(iOS 26.0, *) {
            return base.buttonStyle(.glassProminent)
        } else {
            return base
        }
    }
}

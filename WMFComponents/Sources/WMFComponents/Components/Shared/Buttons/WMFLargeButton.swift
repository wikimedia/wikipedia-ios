import Foundation
import SwiftUI

public struct WMFLargeButton: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let style: WMFButtonStyleKind
    let title: String
    let icon: WMFSFSymbolIcon?
    let forceBackgroundColor: UIColor?
    let forceForegroundColor: UIColor?
    let action: (() -> Void)?

    public init(
        appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current,
        style: WMFButtonStyleKind,
        title: String,
        icon: WMFSFSymbolIcon? = nil,
        forceBackgroundColor: UIColor? = nil,
        forceForegroundColor: UIColor? = nil,
        action: (() -> Void)?
    ) {
        self.appEnvironment = appEnvironment
        self.style = style
        self.title = title
        self.icon = icon
        self.forceBackgroundColor = forceBackgroundColor
        self.forceForegroundColor = forceForegroundColor
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            HStack(alignment: .center, spacing: 4) {
                if let icon, let image = WMFSFSymbolIcon.for(symbol: icon, font: .semiboldSubheadline) {
                    Image(uiImage: image)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Font(WMFFont.for(.semiboldHeadline)))
            }
        }
        .buttonStyle(
            CapsuleButtonStyle(
                kind: style,
                layout: .fill,
                theme: appEnvironment.theme,
                height: 46,
                forceBackgroundColor: forceBackgroundColor,
                forceForegroundColor: forceForegroundColor
            )
        )
    }
}

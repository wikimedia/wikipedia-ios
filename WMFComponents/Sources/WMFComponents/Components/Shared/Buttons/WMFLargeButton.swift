import Foundation
import SwiftUI

public struct WMFLargeButton: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let style: WMFButtonStyleKind
    let title: String
    let forceBackgroundColor: UIColor? // Note: Currently unused, kept for backward compatibility
    let action: (() -> Void)?

    public init(
        appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current,
        style: WMFButtonStyleKind,
        title: String,
        forceBackgroundColor: UIColor? = nil,
        action: (() -> Void)?
    ) {
        self.appEnvironment = appEnvironment
        self.style = style
        self.title = title
        self.forceBackgroundColor = forceBackgroundColor
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            Text(title)
                .font(Font(WMFFont.for(.semiboldHeadline)))
        }
        .buttonStyle(
            CapsuleButtonStyle(
                kind: style,
                layout: .fill,
                theme: appEnvironment.theme,
                height: 46
            )
        )
    }
}

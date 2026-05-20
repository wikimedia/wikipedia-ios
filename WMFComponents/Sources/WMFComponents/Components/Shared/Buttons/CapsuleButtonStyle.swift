import SwiftUI

@available(iOS 26.0, *)
fileprivate struct GlassProminentButton: View {
    let configuration: ButtonStyleConfiguration
    let layout: CapsuleButtonStyle.Layout
    let height: CGFloat
    let tintColor: Color

    var body: some View {
        Button {
            // Empty action - the parent Button's action is what actually fires
        } label: {
            configuration.label
                .applyLayout(layout: layout, height: height)
        }
        .buttonStyle(.glassProminent)
        .tint(tintColor)
        .allowsHitTesting(false)
    }
}

fileprivate extension View {
    @ViewBuilder
    func applyLayout(layout: CapsuleButtonStyle.Layout, height: CGFloat) -> some View {
        switch layout {
        case .fill:
            self
                .frame(maxWidth: .infinity)
                .frame(height: height)
        case .hug:
            self
                .frame(height: height)
        }
    }
}

public enum WMFButtonStyleKind {
    case primary
    case neutral
    case quiet
    case glass
}

public struct CapsuleButtonStyle: ButtonStyle {

    public enum Layout {
        case fill
        case hug
    }

    public let kind: WMFButtonStyleKind
    public let layout: Layout
    public let theme: WMFTheme
    public let height: CGFloat
    let forceBackgroundColor: UIColor?

    let forceForegroundColor: UIColor?

    public init(
        kind: WMFButtonStyleKind,
        layout: Layout = .fill,
        theme: WMFTheme,
        height: CGFloat = 46,
        forceBackgroundColor: UIColor? = nil,
        forceForegroundColor: UIColor? = nil
    ) {
        self.kind = kind
        self.layout = layout
        self.theme = theme
        self.height = height
        self.forceBackgroundColor = forceBackgroundColor
        self.forceForegroundColor = forceForegroundColor
    }

    public func makeBody(configuration: SwiftUI.ButtonStyleConfiguration) -> some View {
        let foreground: UIColor
        let background: UIColor

        switch kind {
        case .primary:
            background = forceBackgroundColor ?? theme.link
            foreground = forceForegroundColor ?? theme.paperBackground
        case .neutral:
            foreground = forceForegroundColor ?? theme.link
            background = forceBackgroundColor ?? theme.baseBackground
        case .quiet:
            foreground = forceForegroundColor ?? theme.link
            background = forceBackgroundColor ?? .clear
        case .glass:
            foreground = forceForegroundColor ?? theme.paperBackground
            background = forceBackgroundColor ?? .clear
        }

        // Glass style uses the glassProminent button style - glass material + background color
        if kind == .glass {
            if #available(iOS 26.0, *) {
                return AnyView(
                    GlassProminentButton(
                        configuration: configuration,
                        layout: layout,
                        height: height,
                        tintColor: Color(uiColor: theme.link)
                    )
                )
            } else {
                return AnyView(
                    configuration.label
                        .foregroundStyle(Color(uiColor: theme.paperBackground))
                        .applyLayout(layout: layout, height: height)
                        .background(
                            Capsule()
                                    .fill(Color(uiColor: theme.link))

                        )
                        .clipShape(Capsule())
                        .opacity(configuration.isPressed ? 0.88 : 1.0)
                )
            }
        }

        return AnyView(
            configuration.label
                .foregroundStyle(Color(uiColor: foreground))
                .applyLayout(layout: layout, height: height)
                .background(
                    Capsule().fill(Color(uiColor: background))
                )
                .clipShape(Capsule())
                .opacity(configuration.isPressed ? 0.88 : 1.0)
        )
    }
}

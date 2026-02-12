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

    public init(
        kind: WMFButtonStyleKind,
        layout: Layout = .fill,
        theme: WMFTheme,
        height: CGFloat = 46
    ) {
        self.kind = kind
        self.layout = layout
        self.theme = theme
        self.height = height
    }

    public func makeBody(configuration: SwiftUI.ButtonStyleConfiguration) -> some View {


        let foreground: UIColor
        let background: UIColor

        switch kind {
        case .primary:
            foreground = theme.paperBackground
            background = theme.link

        case .neutral:
            foreground = theme.link
            background = theme.baseBackground

        case .quiet:
            foreground = theme.link
            background = .clear

        case .glass:
            foreground = theme.paperBackground
            background = .clear
        }

        // Glass style uses the glassPriminent button style
        if kind == .glass {
            if #available(iOS 26.0, *) {
                return AnyView(
                    // We need to create a new Button with .glassPriminent style
                    GlassProminentButton(
                        configuration: configuration,
                        layout: layout,
                        height: height,
                        tintColor: Color(uiColor: theme.link)
                    )
                )
            } else {
                // Fallback for iOS < 26: Material with color overlay
                return AnyView(
                    configuration.label
                        .foregroundStyle(Color(uiColor: theme.paperBackground))
                        .applyLayout(layout: layout, height: height)
                        .background(
                            Capsule()
                                .fill(.regularMaterial)
                                .overlay(
                                    Capsule()
                                        .fill(Color(uiColor: theme.link).opacity(0.2))
                                )
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

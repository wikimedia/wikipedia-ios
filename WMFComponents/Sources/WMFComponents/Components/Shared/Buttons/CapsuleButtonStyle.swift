import SwiftUI

@available(iOS 26.0, *)
fileprivate struct GlassProminentButton: View {
    let configuration: ButtonStyleConfiguration
    let layout: CapsuleButtonStyle.Layout
    let height: CGFloat
    let growsWithContent: Bool
    let tintColor: Color

    var body: some View {
        Button {
            // Empty action - the parent Button's action is what actually fires
        } label: {
            configuration.label
                .applyLayout(layout: layout, height: height, growsWithContent: growsWithContent)
        }
        .buttonStyle(.glassProminent)
        .tint(tintColor)
        .allowsHitTesting(false)
    }
}

fileprivate extension View {
    @ViewBuilder
    func applyLayout(layout: CapsuleButtonStyle.Layout, height: CGFloat, growsWithContent: Bool) -> some View {
        switch layout {
        case .fill:
            self
                .frame(maxWidth: .infinity)
                .applyHeight(height, growsWithContent: growsWithContent)
        case .hug:
            self
                .applyHeight(height, growsWithContent: growsWithContent)
        }
    }

    /// A fixed height, or a minimum height with vertical padding, so that large text and labels on
    /// more than one line are not cut off.
    @ViewBuilder
    func applyHeight(_ height: CGFloat, growsWithContent: Bool) -> some View {
        if growsWithContent {
            self
                .padding(.vertical, 12)
                .frame(minHeight: height)
        } else {
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
    /// When `true`, `height` is the minimum height, and the button grows taller to fit its label.
    /// A taller button keeps the corners of the capsule at its minimum height, so its round ends do
    /// not cut off the corners of a label on more than one line. The glass style keeps its own shape.
    public let growsWithContent: Bool
    let forceBackgroundColor: UIColor?

    let forceForegroundColor: UIColor?

    public init(
        kind: WMFButtonStyleKind,
        layout: Layout = .fill,
        theme: WMFTheme,
        height: CGFloat = 46,
        growsWithContent: Bool = false,
        forceBackgroundColor: UIColor? = nil,
        forceForegroundColor: UIColor? = nil
    ) {
        self.kind = kind
        self.layout = layout
        self.theme = theme
        self.height = height
        self.growsWithContent = growsWithContent
        self.forceBackgroundColor = forceBackgroundColor
        self.forceForegroundColor = forceForegroundColor
    }

    /// A capsule, or for a button that grows, a rounded rectangle that is the same capsule at the minimum height.
    private var shape: AnyShape {
        growsWithContent ? AnyShape(RoundedRectangle(cornerRadius: height / 2)) : AnyShape(Capsule())
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
                        growsWithContent: growsWithContent,
                        tintColor: Color(uiColor: theme.link)
                    )
                )
            } else {
                return AnyView(
                    configuration.label
                        .foregroundStyle(Color(uiColor: theme.paperBackground))
                        .applyLayout(layout: layout, height: height, growsWithContent: growsWithContent)
                        .background(
                            shape
                                    .fill(Color(uiColor: theme.link))

                        )
                        .clipShape(shape)
                        .opacity(configuration.isPressed ? 0.88 : 1.0)
                )
            }
        }

        return AnyView(
            configuration.label
                .foregroundStyle(Color(uiColor: foreground))
                .applyLayout(layout: layout, height: height, growsWithContent: growsWithContent)
                .background(
                    shape.fill(Color(uiColor: background))
                )
                .clipShape(shape)
                .opacity(configuration.isPressed ? 0.88 : 1.0)
        )
    }
}

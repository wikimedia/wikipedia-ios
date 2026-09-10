import SwiftUI

public struct WMFMediumButton: View {

    public struct Configuration {

        public enum Style {
            case primary
            case secondary
        }

        public let style: Style

        public init(style: Style) {
            self.style = style
        }
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private let configuration: Configuration
    private let title: String
    private let image: UIImage?
    private let action: () -> Void

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private var backgroundColor: Color {
        switch configuration.style {
        case .primary:
            return Color(uiColor: theme.link)
        case .secondary:
            return Color(uiColor: theme.paperBackground)
        }
    }

    private var foregroundColor: Color {
        switch configuration.style {
        case .primary:
            return Color(uiColor: theme.paperBackground)
        case .secondary:
            return Color(uiColor: theme.link)
        }
    }

    public init(configuration: Configuration, title: String, image: UIImage? = nil, action: @escaping () -> Void) {
        self.configuration = configuration
        self.title = title
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let image {
                    Image(uiImage: image)
                        .foregroundStyle(foregroundColor)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Font(WMFFont.for(.headline)))
                    .foregroundStyle(foregroundColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

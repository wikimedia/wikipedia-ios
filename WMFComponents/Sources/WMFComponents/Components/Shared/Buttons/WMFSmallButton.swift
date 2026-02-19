import SwiftUI

public struct WMFSmallButton: View {

    public struct Configuration {

        public let style: WMFButtonStyleKind
        public let trailingIcon: UIImage?

        public init(style: WMFButtonStyleKind, trailingIcon: UIImage? = nil) {
            self.style = style
            self.trailingIcon = trailingIcon
        }
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let configuration: Configuration
    let title: String
    let action: (() -> Void)?
    let image: UIImage?

    public init(
        configuration: Configuration,
        title: String,
        image: UIImage? = nil,
        action: (() -> Void)?
    ) {
        self.configuration = configuration
        self.title = title
        self.action = action
        self.image = image
    }

    // MARK: - Body

    public var body: some View {
        let label = HStack(spacing: 4) {
            if let image {
                Image(uiImage: image)
            }

            Text(title)
                .font(Font(WMFFont.for(.mediumSubheadline)))

            if let trailingIcon = configuration.trailingIcon {
                Image(uiImage: trailingIcon)
            }
        }
        .padding(.horizontal, 16)

        Button {
            action?()
        } label: {
            label
        }
        .buttonStyle(
            CapsuleButtonStyle(
                kind: configuration.style,
                layout: .hug,
                theme: appEnvironment.theme,
                height: 46
            )
        )
    }
}

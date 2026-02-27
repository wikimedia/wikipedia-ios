import SwiftUI
import UIKit

public struct WMFReadingListToastView: View {
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    @ObservedObject public var model: WMFReadingListToastModel
    let dismiss: () -> Void

    public init(model: WMFReadingListToastModel, dismiss: @escaping () -> Void) {
        self.model = model
        self.dismiss = dismiss
    }

    private var theme: WMFTheme { appEnvironment.theme }

    public var body: some View {
        let config = model.config
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        HStack(alignment: .center, spacing: 16) {
            if let icon = config.icon {
                iconView(icon)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(config.title)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let buttonTitle = config.buttonTitle {
                    Button {
                        config.buttonAction?()
                    } label: {
                        Text(buttonTitle)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundStyle(Color(uiColor: theme.link))
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .onTapGesture { config.tapAction?() }
        .modifier(ToastGlassModifier(theme: theme, shape: shape))

    }
    @ViewBuilder
    private func iconView(_ icon: UIImage) -> some View {
        let isTemplateLike = icon.isSymbolImage || icon.renderingMode == .alwaysTemplate

        if isTemplateLike {
            Image(uiImage: icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .frame(width: 30, height: 30)
        } else {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 45, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct ToastGlassModifier: ViewModifier {
    let theme: WMFTheme
    let shape: RoundedRectangle

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    .regular
                        .tint(Color(uiColor: theme.paperBackground).opacity(0.85))
                        .interactive()
                )
                .clipShape(shape)
        } else {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: theme.paperBackground))
                .clipShape(shape)
        }
    }
}

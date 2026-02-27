import SwiftUI
import UIKit

public struct WMFHintView: View {
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    @ObservedObject public var model: WMFHintModel
    let dismiss: () -> Void

    public init(model: WMFHintModel, dismiss: @escaping () -> Void) {
        self.model = model
        self.dismiss = dismiss
    }

    private var theme: WMFTheme { appEnvironment.theme }

    public var body: some View {
        let config = model.config

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
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .onTapGesture {
            config.tapAction?()
        }
        .background(.clear)
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

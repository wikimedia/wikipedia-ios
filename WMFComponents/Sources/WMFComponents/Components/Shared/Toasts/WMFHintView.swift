import SwiftUI
import UIKit

public struct WMFHintView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @ObservedObject public var model: WMFHintModel
    let dismiss: () -> Void

    public init(model: WMFHintModel, dismiss: @escaping () -> Void) {
        self.model = model
        self.dismiss = dismiss
    }

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public var body: some View {
        let config = model.config

        HStack(alignment: .center, spacing: 12) {
            if let icon = config.icon {
                let isSymbolicIcon = icon.isSymbolImage

                if isSymbolicIcon {
                    Image(uiImage: icon)
                        .renderingMode(.template)
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .frame(width: 24, height: 24)
                } else {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 45, height: 45)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(config.title)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                }
            }

            Spacer()

            if let buttonTitle = config.buttonTitle {
                Button(action: { config.buttonAction?() }) {
                    Text(buttonTitle)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .foregroundStyle(Color(uiColor: theme.link))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(uiColor: theme.paperBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            config.tapAction?()
        }
    }
}

import SwiftUI

struct WMFToastView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let config: WMFToastConfig
    let dismiss: () -> Void

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let icon = config.icon {
                Image(uiImage: icon.withConfiguration(UIImage.SymbolConfiguration(weight: .semibold)))
                    .renderingMode(.template)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                    .frame(width: 45, height: 45)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(config.title)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.footnote)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                }

                if let buttonTitle = config.buttonTitle {
                    Button(action: {
                        config.buttonAction?()
                        dismiss()
                    }) {
                        Text(buttonTitle)
                            .font(Font(WMFFont.for(.boldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                }
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            if let tapAction = config.tapAction {
                tapAction()
            }
        }
    }
}

import SwiftUI

struct WMFToastView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let config: WMFToastConfig
    let dismiss: () -> Void

    var theme: WMFTheme { appEnvironment.theme }

    private var isSingleLineStyle: Bool {
        config.subtitle == nil && config.buttonTitle == nil
    }

    private var iconSize: CGFloat { 28 } 
    private var vPad: CGFloat { isSingleLineStyle ? 12 : 14 }
    private var hPad: CGFloat { 20 }
    private var spacing: CGFloat { 16 }

    var body: some View {
        if #available(iOS 26.0, *) {
            contentView
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, vPad)
                .padding(.horizontal, hPad)
                .padding(.vertical, 6)
                .glassEffect(
                    .regular
                        .tint(Color(uiColor: theme.paperBackground).opacity(0.85))
                        .interactive()
                )
                .clipShape(Capsule())
                .onTapGesture { config.tapAction?() }

        } else {
            contentView
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, vPad)
                .padding(.horizontal, hPad)
                .padding(.vertical, 6)
                .onTapGesture { config.tapAction?() }

                .background(Color(uiColor: theme.paperBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .circular))
        }
    }

    @ViewBuilder
    var contentView: some View {
        HStack(alignment: .center, spacing: spacing) {

            if let icon = config.icon {
                Image(uiImage: icon.withConfiguration(UIImage.SymbolConfiguration(weight: .semibold)))
                    .renderingMode(.template)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                    .frame(width: iconSize, height: iconSize)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: isSingleLineStyle ? 0 : 6) {
                Text(config.title)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.footnote)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let buttonTitle = config.buttonTitle {
                    Button {
                        config.buttonAction?()
                        dismiss()
                    } label: {
                        Text(buttonTitle)
                            .font(Font(WMFFont.for(.boldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                }
            }
        }

    }

}

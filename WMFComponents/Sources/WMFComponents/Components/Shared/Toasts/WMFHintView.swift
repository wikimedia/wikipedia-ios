import SwiftUI

public struct WMFHintView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFHintViewModel
    let dismiss: () -> Void

    public init(viewModel: WMFHintViewModel, dismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.dismiss = dismiss
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let icon = viewModel.icon {
                // Check if this is a symbolic icon or a photo thumbnail
                // Symbolic icons should be template-rendered and smaller
                // Article thumbnails should show the full image and be larger
                let isSymbolicIcon = icon.isSymbolImage

                if isSymbolicIcon {
                    Image(uiImage: icon)
                        .renderingMode(.template)
                        .foregroundStyle(Color(uiColor: theme.text))
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
                Text(viewModel.title)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))

                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                }
            }

            Spacer()

            if let buttonTitle = viewModel.buttonTitle {
                Button(action: {
                    viewModel.buttonAction?()
                }) {
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
            viewModel.tapAction?()
        }
    }
}

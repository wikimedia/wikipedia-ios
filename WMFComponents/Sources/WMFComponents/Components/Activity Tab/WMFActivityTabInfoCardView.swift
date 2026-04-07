import SwiftUI

struct WMFActivityTabInfoCardView<Content: View>: View {
    private let icon: UIImage?
    private let title: String
    private let dateText: String?
    private let onTapModule: (() -> Void)?
    private let content: () -> Content
    private let showArrowAnyways: Bool

    init(
        icon: UIImage?,
        title: String,
        dateText: String?,
        onTapModule: (() -> Void)?,
        @ViewBuilder content: @escaping () -> Content = { EmptyView()},
        showArrowAnyways: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.dateText = dateText
        self.content = content
        self.onTapModule = onTapModule
        self.showArrowAnyways = showArrowAnyways
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }
    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = 12

    var body: some View {
            VStack(spacing: 16) {
                HStack {
                    if let icon {
                        Image(uiImage: icon)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .padding(.leading, 0)
                            .accessibilityHidden(true)
                    }
                    Text(title)
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldCaption1)))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    if let dateText {
                        HStack {
                            Text("\(dateText)")
                                .foregroundStyle(Color(theme.secondaryText))
                                .font(Font(WMFFont.for(.caption1)))
                            if let uiImage = WMFSFSymbolIcon.for(symbol: .chevronForward) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: iconSize, height: iconSize)
                                    .foregroundStyle(Color(theme.secondaryText))
                                    .accessibilityHidden(true)
                            }
                        }
                    } else if showArrowAnyways {
                        if let uiImage = WMFSFSymbolIcon.for(symbol: .chevronForward) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(Color(theme.secondaryText))
                                .accessibilityHidden(true)
                        }
                    }
                }

                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(theme.paperBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(theme.baseBackground), lineWidth: 0.5)
            )
            .onTapGesture {
                onTapModule?()
            }
    }
}

import SwiftUI

struct WMFActivityTabInfoCardView<Content: View>: View {
    let icon: UIImage?
    let title: String
    let dateText: String?
    let amount: Int
    let onTapDateText: () -> Void
    // Content will eventually be graphs or images or whatever
    let content: () -> Content

    public init( icon: UIImage?, title: String, dateText: String?, amount: Int = 0, onTapDateText: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.icon = icon
        self.title = title
        self.dateText = dateText
        self.amount = amount
        self.content = content
        self.onTapDateText = onTapDateText
    }
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                if let icon = icon {
                    Image(uiImage: icon)
                }
                Text(title)
                    .foregroundStyle(Color(theme.text))
                    .font(Font(WMFFont.for(.boldCaption1)))
                Spacer()
                HStack(spacing: 8) {
                    if let dateText = dateText {
                        Text(dateText)
                            .foregroundStyle(Color(theme.secondaryText))
                            .font(Font(WMFFont.for(.caption1)))
                    }
                    if let chevronRight = WMFSFSymbolIcon.for(symbol: .chevronForward, font: .caption1) {
                        Image(uiImage: chevronRight)
                            .foregroundStyle(Color(theme.secondaryText))
                    }
                }
                .onTapGesture {
                    onTapDateText()
                }
            }

            HStack(alignment: .center) {
                Text("\(amount)")
                    .foregroundStyle(Color(theme.text))
                    .font(Font(WMFFont.for(.boldTitle1)))
                Spacer()
                content()
            }
        }
        .padding(16)
        .background(Color(theme.paperBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(theme.baseBackground), lineWidth: 0.5)
        )
    }
}

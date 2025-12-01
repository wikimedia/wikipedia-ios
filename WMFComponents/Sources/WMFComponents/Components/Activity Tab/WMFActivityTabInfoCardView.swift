import SwiftUI

struct WMFActivityTabInfoCardView<Content: View>: View {
    private let icon: UIImage?
    private let title: String
    private let dateText: String?
    private let amount: Int
    private let onTapModule: () -> Void
    private let content: () -> Content
    private let contentAccessibilityLabels: [String]

    init(
        icon: UIImage?,
        title: String,
        dateText: String?,
        amount: Int = 0,
        contentAccessibilityLabels: [String] = [],
        onTapModule: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.dateText = dateText
        self.amount = amount
        self.contentAccessibilityLabels = contentAccessibilityLabels
        self.content = content
        self.onTapModule = onTapModule
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        Button(action: onTapModule) {
            VStack(spacing: 24) {
                HStack {
                    if let icon {
                        Image(uiImage: icon)
                    }
                    Text(title)
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldCaption1)))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    if let dateText {
                        Text(dateText)
                            .foregroundStyle(Color(theme.secondaryText))
                            .font(Font(WMFFont.for(.caption1)))
                    }
                }

                HStack(alignment: .bottom) {
                    Text("\(amount)")
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldTitle1)))
                    Spacer()
                    content()
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(Color(theme.paperBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(theme.baseBackground), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(accessibilityString)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        let formattedAmount = numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        
        var parts = [title]
        if let dateText { parts.append(dateText) }
        parts.append(formattedAmount)
        parts.append(contentsOf: contentAccessibilityLabels)
        return parts.joined(separator: ", ")
    }

}

import SwiftUI

struct WMFActivityTabInfoCardView<Content: View>: View {
    private let icon: UIImage?
    private let title: String
    private let dateText: String?
    private let additionalAccessibilityLabel: String?
    private let onTapModule: (() -> Void)?
    private let content: () -> Content

    init(
        icon: UIImage?,
        title: String,
        dateText: String?,
        additionalAccessibilityLabel: String?,
        onTapModule: (() -> Void)?,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.dateText = dateText
        self.additionalAccessibilityLabel = additionalAccessibilityLabel
        self.content = content
        self.onTapModule = onTapModule
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        Button(action: { onTapModule?() }) {
            VStack(spacing: 24) {
                HStack {
                    if let icon {
                        Image(uiImage: icon)
                    }
                    Text(title)
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldCaption1)))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                    Spacer()
                    if let dateText {
                        HStack {
                            Text("\(dateText)")
                                .foregroundStyle(Color(theme.secondaryText))
                                .font(Font(WMFFont.for(.caption1)))
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color(theme.secondaryText))
                                .font(Font(WMFFont.for(.caption1)))
                        }
                    }
                }

                content()
            }
            .padding(16)
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
        var parts = [title]
        if let dateText { parts.append(dateText) }
        if let additionalAccessibilityLabel { parts.append(additionalAccessibilityLabel)}
        return parts.joined(separator: ", ")
    }
}

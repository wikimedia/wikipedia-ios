import SwiftUI
import WMFData

struct WMFEditModeOptionsCard: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    private let selectedMode: WMFEditMode
    private let showsExternalLinkIcon: Bool
    private let cornerRadius: CGFloat
    private let didSelect: (WMFEditMode) -> Void

    init(selectedMode: WMFEditMode, showsExternalLinkIcon: Bool = true, cornerRadius: CGFloat = 32, didSelect: @escaping (WMFEditMode) -> Void) {
        self.selectedMode = selectedMode
        self.showsExternalLinkIcon = showsExternalLinkIcon
        self.cornerRadius = cornerRadius
        self.didSelect = didSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            optionRow(mode: .visual)
            Divider()
                .padding(.horizontal, 16)
            optionRow(mode: .source)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(uiColor: theme.chromeBackground))
        )
    }

    private func optionRow(mode: WMFEditMode) -> some View {
        Button {
            didSelect(mode)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading) {
                    HStack(spacing: 8) {
                        Text(mode.localizedTitle)
                            .font(Font(WMFFont.for(.headline)))
                            .accessibilityAddTraits(selectedMode == mode ? [.isSelected] : [])

                        if showsExternalLinkIcon, mode == .visual, let uiImage = WMFSFSymbolIcon.for(symbol: .arrowUpForward, font: .subheadline) {
                            Image(uiImage: uiImage)
                        }
                    }
                    .foregroundColor(Color(uiColor: theme.text))

                    HStack(alignment: .top, spacing: 8) {
                        Text(mode.localizedSubtitle)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        WMFCheckmarkView(isSelected: true, configuration: .init(style: .default))
                            .opacity(selectedMode == mode ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(WMFEditModeRowButtonStyle())
        .accessibilityElement(children: .combine)
    }
}

private struct WMFEditModeRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

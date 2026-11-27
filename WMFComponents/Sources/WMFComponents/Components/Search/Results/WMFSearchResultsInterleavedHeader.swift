import SwiftUI

/// The row above the interleaved list: a Beta pill and an info button that explains the experiment.
struct WMFSearchResultsInterleavedHeader: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSearchResultsViewModel

    private static let minimumTouchTarget: CGFloat = 44

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            WMFBetaBadge(label: viewModel.betaLabel)
            Button {
                viewModel.showInterleavedInfo()
            } label: {
                // The touch target includes the gap after the Beta pill and the trailing margin. The icon
                // then stays near the pill and aligns with the content of the cards.
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .infoCircle) ?? UIImage())
                    .foregroundStyle(Color(theme.secondaryText))
                    .padding(.leading, WMFSpacing.small)
                    .padding(.trailing, viewModel.horizontalPadding)
                    .frame(minHeight: Self.minimumTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(viewModel.accessibilityText(viewModel.interleavedInfoAccessibilityLabel)))
            .accessibilityIdentifier(AccessibilityIdentifiers.Search.interleavedResultsInfoButton)
        }
        .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.interleavedResultsHeader)
    }
}

import SwiftUI
import WMFData

/// A result of the semantic search interleaved treatment in the list. The row draws the card, loads its
/// thumbnail and counts, and opens the article on tap.
struct WMFSearchResultInterleavedRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSearchResultsViewModel
    @ObservedObject var rowViewModel: WMFSearchResultInterleavedRowViewModel
    let result: WMFSearchResultsViewModel.SearchResult
    @AccessibilityFocusState.Binding var focusedElementID: String?

    @State private var thumbnail: UIImage?

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    var body: some View {
        Button {
            viewModel.tap(result)
        } label: {
            WMFSearchResultInterleavedCard(
                rowViewModel: rowViewModel,
                thumbnail: thumbnail,
                showsThumbnail: result.thumbnailURL != nil,
                horizontalPadding: viewModel.horizontalPadding,
                isRightToLeft: viewModel.isRightToLeft)
            .task(id: result.thumbnailURL) {
                thumbnail = await viewModel.loadImage(url: result.thumbnailURL)
            }
            .task(id: result.id) {
                await rowViewModel.loadAttribution()
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: WMFSpacing.small / 2, leading: 0, bottom: WMFSpacing.small / 2, trailing: 0))
        .listRowBackground(Color(theme.paperBackground))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(rowViewModel.accessibilityText))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.result(result.title))
        .accessibilityFocused($focusedElementID, equals: result.id)
        .searchResultActions(viewModel: viewModel, result: result)
    }
}

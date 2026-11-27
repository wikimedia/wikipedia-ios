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

    private static let feedbackRowMinimumHeight: CGFloat = 64

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    /// The tap on the card opens the article. The feedback row sits below the button, not inside it,
    /// so a tap on a thumb never opens the article. The swipe actions are on the whole row, so the card and
    /// the feedback row slide together. The long-press menu is on the card, but the `List` attaches it to
    /// the whole row, so a long press on the feedback row also opens it. VoiceOver reads the card and then
    /// each thumb.
    var body: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.tap(result)
            } label: {
                WMFSearchResultInterleavedCard(
                    rowViewModel: rowViewModel,
                    thumbnail: thumbnail,
                    showsThumbnail: result.thumbnailURL != nil,
                    horizontalPadding: viewModel.horizontalPadding,
                    // The feedback row follows the card and has its own height, so the card keeps a smaller bottom padding.
                    bottomPadding: WMFSpacing.small,
                    isRightToLeft: viewModel.isRightToLeft)
                .task(id: result.thumbnailURL) {
                    thumbnail = await viewModel.loadImage(url: result.thumbnailURL)
                }
                .task(id: result.id) {
                    await rowViewModel.loadAttribution()
                }
            }
            .buttonStyle(.plain)
            .searchResultContextMenu(viewModel: viewModel, result: result)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(rowViewModel.accessibilityText))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityIdentifiers.Search.result(result.title))
            .accessibilityFocused($focusedElementID, equals: result.id)
            .accessibilityAction(named: Text(viewModel.localizedStrings.shareActionTitle)) {
                viewModel.share(result, source: .swipe)
            }
            .accessibilityActions {
                if result.isSavable {
                    Button(result.isSaved ? viewModel.localizedStrings.unsaveActionTitle : viewModel.localizedStrings.saveActionTitle) {
                        viewModel.saveOrUnsave(result, source: .swipe)
                    }
                }
            }

            feedbackRow
        }
        .background(Color(theme.midBackground))
        .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
        .listRowInsets(EdgeInsets(top: WMFSpacing.small / 2, leading: 0, bottom: WMFSpacing.small / 2, trailing: 0))
        .listRowBackground(Color(theme.paperBackground))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .contain)
        .searchResultSwipeActions(viewModel: viewModel, result: result)
    }

    private var feedbackRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(rowViewModel.localizedStrings.feedbackQuestion)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                WMFSemanticSearchFeedbackThumbButton(
                    rating: .positive,
                    isSelected: rowViewModel.rating == .positive,
                    accessibilityLabel: rowViewModel.localizedStrings.thumbsUpAccessibilityLabel,
                    accessibilityIdentifier: AccessibilityIdentifiers.Search.interleavedResultFeedbackThumbsUpButton(result.title),
                    action: { rowViewModel.rate(.positive) }
                )
                WMFSemanticSearchFeedbackThumbButton(
                    rating: .negative,
                    isSelected: rowViewModel.rating == .negative,
                    accessibilityLabel: rowViewModel.localizedStrings.thumbsDownAccessibilityLabel,
                    accessibilityIdentifier: AccessibilityIdentifiers.Search.interleavedResultFeedbackThumbsDownButton(result.title),
                    action: { rowViewModel.rate(.negative) }
                )
            }
            .padding(.leading, viewModel.horizontalPadding)
            // The icon, not the 48 pt touch target, lines up with the card's trailing margin.
            .padding(.trailing, max(viewModel.horizontalPadding - (WMFSemanticSearchFeedbackThumbButton.size - WMFSemanticSearchFeedbackThumbButton.iconSize) / 2, 0))
            .frame(minHeight: Self.feedbackRowMinimumHeight)
        }
    }
}

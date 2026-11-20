import SwiftUI

struct WMFSearchResultRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSearchResultsViewModel
    let result: WMFSearchResultsViewModel.SearchResult
    @AccessibilityFocusState.Binding var focusedElementID: String?

    @State private var thumbnail: UIImage?
    @Environment(\.displayScale) private var displayScale

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var attributedTitle: AttributedString {
        let styles = HtmlUtils.Styles(
            font: WMFFont.for(.callout),
            boldFont: WMFFont.for(.boldCallout),
            italicsFont: WMFFont.for(.italicCallout),
            boldItalicsFont: WMFFont.for(.boldItalicCallout),
            color: theme.text,
            linkColor: theme.link,
            lineSpacing: 1)
        return viewModel.attributedTitle(for: result, styles: styles, boldFont: WMFFont.for(.boldCallout))
    }

    var body: some View {
        Button {
            viewModel.tap(result)
        } label: {
            content
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(theme.paperBackground))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.result(result.title))
        .accessibilityFocused($focusedElementID, equals: result.id)
        .searchResultActions(viewModel: viewModel, result: result)
    }

    private var content: some View {
        VStack(spacing: 0) {
            rowContent
            Divider()
                .background(Color(theme.border))
                .frame(height: max(1.0 / displayScale, 0.5))
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(attributedTitle)
                    .lineLimit(1)
                if let description = result.description, let displayedDescription = result.displayedDescription {
                    Text(displayedDescription)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(theme.secondaryText))
                        .lineLimit(1)
                        .accessibilityLabel(Text(viewModel.accessibilityText(description)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if result.thumbnailURL != nil {
                thumbnailView
            }
        }
        .frame(minHeight: 40)
        .padding(EdgeInsets(top: 10, leading: viewModel.horizontalPadding, bottom: 10, trailing: viewModel.horizontalPadding))
        .contentShape(Rectangle())
        .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
        .task(id: result.thumbnailURL) {
            thumbnail = await viewModel.loadImage(url: result.thumbnailURL)
        }
    }

    private var thumbnailView: some View {
        ZStack {
            Color(theme.midBackground)
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .accessibilityHidden(true)
    }
}

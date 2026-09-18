import SwiftUI

struct WMFSearchResultRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSearchResultsViewModel
    let result: WMFSearchResultsViewModel.SearchResult

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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                viewModel.share(result, source: .swipe)
            } label: {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
                    .accessibilityLabel(viewModel.localizedStrings.shareActionTitle)
            }
            .tint(Color(theme.secondaryAction))
            .labelStyle(.iconOnly)
            if result.isSavable {
                Button {
                    viewModel.saveOrUnsave(result, source: .swipe)
                } label: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: result.isSaved ? .bookmarkFill : .bookmark) ?? UIImage())
                        .accessibilityLabel(result.isSaved ? viewModel.localizedStrings.unsaveActionTitle : viewModel.localizedStrings.saveActionTitle)
                }
                .tint(Color(theme.link))
                .labelStyle(.iconOnly)
            }
        }
        .contextMenu {
            Button {
                viewModel.open(result)
            } label: {
                Text(viewModel.localizedStrings.openActionTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
            }
            if result.isArticle {
                Button {
                    viewModel.openInNewTab(result)
                } label: {
                    Text(viewModel.localizedStrings.openInNewTabActionTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIcon) ?? UIImage())
                }
                Button {
                    viewModel.openInBackgroundTab(result)
                } label: {
                    Text(viewModel.localizedStrings.openInBackgroundTabActionTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIconBackground) ?? UIImage())
                }
            }
            if result.isSavable {
                Button {
                    viewModel.saveOrUnsave(result, source: .contextMenu)
                } label: {
                    Text(result.isSaved ? viewModel.localizedStrings.unsaveActionTitle : viewModel.localizedStrings.saveActionTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: result.isSaved ? .bookmarkFill : .bookmark) ?? UIImage())
                }
            }
            if result.hasLocation {
                Button {
                    viewModel.openOnMap(result)
                } label: {
                    Text(viewModel.localizedStrings.viewOnMapActionTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .map) ?? UIImage())
                }
            }
            Button {
                viewModel.share(result, source: .contextMenu)
            } label: {
                Text(viewModel.localizedStrings.shareActionTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
            }
        } preview: {
            WMFSearchResultPreview(viewModel: viewModel, result: result)
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        viewModel.geometryFrames[result.id] = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        viewModel.geometryFrames[result.id] = newFrame
                    }
            }
            .allowsHitTesting(false)
        )
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

private struct WMFSearchResultPreview: View {
    @ObservedObject var viewModel: WMFSearchResultsViewModel
    let result: WMFSearchResultsViewModel.SearchResult

    @State private var previewViewModel: WMFArticlePreviewViewModel?

    var body: some View {
        WMFArticlePreviewView(viewModel: previewViewModel ?? viewModel.previewViewModel(for: result))
            .task {
                previewViewModel = await viewModel.loadPreviewViewModel(for: result)
            }
    }
}

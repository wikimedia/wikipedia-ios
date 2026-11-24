import SwiftUI

/// The swipe actions that every search result row shares.
private struct WMFSearchResultSwipeActions: ViewModifier {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSearchResultsViewModel
    let result: WMFSearchResultsViewModel.SearchResult

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    func body(content: Content) -> some View {
        content
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
    }
}

/// The long-press menu with its article preview, and the frame tracking that every search result row shares.
/// The frame is the one that the Share popover points at.
private struct WMFSearchResultContextMenu: ViewModifier {

    @ObservedObject var viewModel: WMFSearchResultsViewModel
    let result: WMFSearchResultsViewModel.SearchResult

    func body(content: Content) -> some View {
        content
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

extension View {
    /// Adds the swipe actions and the long-press menu of a search result row.
    func searchResultActions(viewModel: WMFSearchResultsViewModel, result: WMFSearchResultsViewModel.SearchResult) -> some View {
        searchResultContextMenu(viewModel: viewModel, result: result)
            .searchResultSwipeActions(viewModel: viewModel, result: result)
    }

    /// Adds only the swipe actions. A row that has parts outside the long-press menu uses this one.
    func searchResultSwipeActions(viewModel: WMFSearchResultsViewModel, result: WMFSearchResultsViewModel.SearchResult) -> some View {
        modifier(WMFSearchResultSwipeActions(viewModel: viewModel, result: result))
    }

    /// Adds only the long-press menu and the frame of the result.
    func searchResultContextMenu(viewModel: WMFSearchResultsViewModel, result: WMFSearchResultsViewModel.SearchResult) -> some View {
        modifier(WMFSearchResultContextMenu(viewModel: viewModel, result: result))
    }
}

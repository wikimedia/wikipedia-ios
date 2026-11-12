import SwiftUI
import WMFData
import WMFNativeLocalizations

public struct WMFSavedAllArticlesView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSavedAllArticlesViewModel
    /// Mirrors `discoverHeader` so the card fades in and out instead of popping.
    @State private var shownDiscoverHeader: WMFSavedDiscoverHeaderViewModel.Header?
    @Environment(\.isSearching) private var isSearching
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private let emptyStateTitle = CommonStrings.allArticlesEmptySavedTitle
    private let emptyStateMessage = CommonStrings.allArticlesEmptySavedSubtitle
    private let addToListTitle = CommonStrings.addToReadingListShortActionTitle
    private let unsaveTitle = CommonStrings.shortUnsaveTitle
    
    public init(viewModel: WMFSavedAllArticlesViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading, .undefined:
                ProgressView()
            case .empty:
                VStack(spacing: 0) {
                    discoverHeaderCard
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .data:
                articleListView
            }
        }
        .background(Color(uiColor: appEnvironment.theme.paperBackground))
        .onAppear {
            viewModel.loadArticles()
            shownDiscoverHeader = discoverHeader
        }
        .onChange(of: discoverHeader) { _, header in
            withAnimation {
                shownDiscoverHeader = header
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            if verticalSizeClass != .compact {
                Image("saved-blank", bundle: Bundle.module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
            
            Text(emptyStateTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.text))
            
            Text(emptyStateMessage)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(uiColor: appEnvironment.theme.paperBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Saved.allArticlesEmptyView)
    }
    
    // MARK: - Discover

    /// The card shows while the reader is not editing or searching.
    private var discoverHeader: WMFSavedDiscoverHeaderViewModel.Header? {
        guard !viewModel.isEditing, !isSearching else { return nil }
        return viewModel.discoverHeader
    }

    @ViewBuilder
    private var discoverHeaderCard: some View {
        if let shownDiscoverHeader, let discoverHeaderViewModel = viewModel.discoverHeaderViewModel {
            WMFSavedDiscoverHeaderView(header: shownDiscoverHeader, viewModel: discoverHeaderViewModel)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var discoverHeaderRow: some View {
        if let shownDiscoverHeader, let discoverHeaderViewModel = viewModel.discoverHeaderViewModel {
            WMFSavedDiscoverHeaderView(header: shownDiscoverHeader, viewModel: discoverHeaderViewModel)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: appEnvironment.theme.paperBackground))
                .transition(.opacity)
        }
    }

    // MARK: - Article List
    
    private var articleListView: some View {
        VStack(spacing: 0) {
            List {
                discoverHeaderRow
                ForEach(viewModel.filteredArticles, id: \.id) { article in
                    let rowModel = viewModel.rowViewModel(for: article)
                    
                    VStack(spacing: 0) {
                        WMFPageRowSaved(
                            viewModel: rowModel,
                            onTap: { fromLongPress in
                                if viewModel.isEditing {
                                    viewModel.toggleSelection(for: article)
                                } else {
                                    viewModel.tapArticle(article, fromLongPress: fromLongPress)
                                }
                            },
                            onDelete: { fromLongPress in
                                viewModel.deleteArticles([article], fromLongPress: fromLongPress)
                            },
                            onShare: { cgRect, fromLongPress in
                                viewModel.tapShare(article, cgRect: cgRect, fromLongPress: fromLongPress)
                            },
                            onOpenInNewTab: {
                                viewModel.tapOpenInNewTab(article)
                            },
                            onOpenInBackgroundTab: {
                                viewModel.didTapOpenInBackgroundTab?(article)
                            }
                        )
                        .accessibilityIdentifier(AccessibilityIdentifiers.Saved.allArticlesRow(article.title))
                        
                        Divider()
                            .background(Color(uiColor: appEnvironment.theme.border))
                            .frame(height: max(1.0 / UIScreen.main.scale, 0.5))
                    }
                    .readableWidth()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(uiColor: rowModel.isSelected ? appEnvironment.theme.batchSelectionBackground : appEnvironment.theme.paperBackground))
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Saved.allArticlesList)
            .refreshable {
                await viewModel.didPullToRefresh?()
            }
            .background(Color(uiColor: appEnvironment.theme.paperBackground))

            if viewModel.isEditing {
                editingToolbar
            }
        }
    }
     
    
    // MARK: - Editing Toolbar
    
    private var editingToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(uiColor: appEnvironment.theme.border))
            HStack {
                Button(action: {
                    viewModel.addSelectedToList()
                }) {
                    editingToolbarText(text: addToListTitle, isEnabled: viewModel.hasSelection)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Saved.allArticlesEditingToolbarAddToListButton)
                .disabled(!viewModel.hasSelection)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: {
                    viewModel.deleteSelectedArticles()
                }) {
                    editingToolbarText(text: unsaveTitle, isEnabled: viewModel.hasSelection)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Saved.allArticlesEditingToolbarUnsaveButton)
                .disabled(!viewModel.hasSelection)
                .frame(maxWidth: .infinity)
            }
            .padding([.top, .bottom], 12)
            .background(Color(uiColor: appEnvironment.theme.midBackground))
        }
        
    }
    
    private func editingToolbarText(text: String, isEnabled: Bool) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundColor(isEnabled ? Color(uiColor: appEnvironment.theme.link) : Color(uiColor: appEnvironment.theme.secondaryText))
    }
}

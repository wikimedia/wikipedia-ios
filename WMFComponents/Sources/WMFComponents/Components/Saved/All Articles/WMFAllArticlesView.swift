import SwiftUI
import WMFData

public struct WMFAllArticlesView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFAllArticlesViewModel
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    public init(viewModel: WMFAllArticlesViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading, .undefined:
                ProgressView()
            case .empty:
                emptyStateView
            case .data:
                articleListView
            }
        }
        .onAppear {
            viewModel.loadArticles()
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
            
            Text(viewModel.localizedStrings.emptyStateTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.text))
            
            Text(viewModel.localizedStrings.emptyStateMessage)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Article List
    
    private var articleListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.filteredArticles, id: \.id) { article in
                    WMFAsyncPageRowSaved(
                        viewModel: viewModel.rowViewModel(for: article),
                        isEditing: viewModel.isEditing,
                        isSelected: viewModel.isSelected(article),
                        theme: appEnvironment.theme,
                        onTap: {
                            if viewModel.isEditing {
                                viewModel.toggleSelection(for: article)
                            } else {
                                viewModel.didTapArticle?(article)
                            }
                        },
                        onDelete: {
                            viewModel.deleteArticle(article)
                        },
                        onShare: {
                            viewModel.didTapShare?(article)
                        }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.visible)
                    .listRowSeparatorTint(Color(uiColor: appEnvironment.theme.newBorder))
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.didPullToRefresh?()
            }

            if viewModel.isEditing {
                editingToolbar
            }
        }
    }
     
    
    // MARK: - Editing Toolbar
    
    private var editingToolbar: some View {
        HStack {
            Button(action: {
                viewModel.addSelectedToList()
            }) {
                Text(viewModel.localizedStrings.addToList)
                    .foregroundColor(viewModel.hasSelection ? Color(uiColor: appEnvironment.theme.link) : Color(uiColor: appEnvironment.theme.secondaryText))
            }
            .disabled(!viewModel.hasSelection)
            
            Spacer()
            
            Button(action: {
                viewModel.deleteSelectedArticles()
            }) {
                Text(viewModel.localizedStrings.unsave)
                    .foregroundColor(viewModel.hasSelection ? Color(uiColor: appEnvironment.theme.link) : Color(uiColor: appEnvironment.theme.secondaryText))
            }
            .disabled(!viewModel.hasSelection)
        }
        .padding()
        .background(Color(uiColor: appEnvironment.theme.paperBackground))
    }
}

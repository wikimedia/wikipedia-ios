import SwiftUI
import WMFData

public struct WMFSavedAllArticlesView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSavedAllArticlesViewModel
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    public init(viewModel: WMFSavedAllArticlesViewModel) {
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
        .background(Color(uiColor: appEnvironment.theme.paperBackground))
        .onAppear {
            viewModel.loadArticles()
            if viewModel.state == .data {
                viewModel.didShowDataStateOnAppearance?()
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
            
            Text(viewModel.localizedStrings.emptyStateTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.text))
            
            Text(viewModel.localizedStrings.emptyStateMessage)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(uiColor: appEnvironment.theme.paperBackground))
    }
    
    // MARK: - Article List
    
    private var articleListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.filteredArticles, id: \.id) { article in
                    let rowModel = viewModel.rowViewModel(for: article)
                    
                    VStack(spacing: 0) {
                        WMFAsyncPageRowSaved(
                            viewModel: rowModel,
                            onTap: {
                                if viewModel.isEditing {
                                    viewModel.toggleSelection(for: article)
                                } else {
                                    viewModel.didTapArticle?(article)
                                }
                            },
                            onDelete: {
                                viewModel.deleteArticles([article])
                            },
                            onShare: { cgRect in
                                viewModel.didTapShare?(article, cgRect)
                            },
                            onOpenInNewTab: {
                                viewModel.didTapOpenInNewTab?(article)
                            },
                            onOpenInBackgroundTab: {
                                viewModel.didTapOpenInBackgroundTab?(article)
                            }
                        )
                        
                        Divider()
                            .background(Color(uiColor: appEnvironment.theme.border))
                            .frame(height: max(1.0 / UIScreen.main.scale, 0.5))
                    }
                    
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(uiColor: rowModel.isSelected ? appEnvironment.theme.batchSelectionBackground : appEnvironment.theme.paperBackground))
                }
            }
            .listStyle(.plain)
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
                    editingToolbarText(text: viewModel.localizedStrings.addToList, isEnabled: viewModel.hasSelection)
                }
                .disabled(!viewModel.hasSelection)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: {
                    viewModel.deleteSelectedArticles()
                }) {
                    editingToolbarText(text: viewModel.localizedStrings.unsave, isEnabled: viewModel.hasSelection)
                }
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

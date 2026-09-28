import SwiftUI

public struct WMFSemanticSearchResultsView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSemanticSearchResultsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFSemanticSearchResultsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
            .background(Color(theme.paperBackground))
            .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchResultsView)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            emptyState
        case .error(let errorViewModel):
            WMFErrorView(viewModel: errorViewModel) {
                viewModel.load()
            }
        case .results:
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: WMFSpacing.large) {
                ForEach(viewModel.results) { item in
                    WMFSemanticSearchResultCardView(viewModel: item)
                    .onAppear {
                        viewModel.loadMoreIfNeeded(after: item)
                    }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, WMFSpacing.small)
                }
            }
            .padding(.horizontal, WMFSpacing.large)
            .padding(.top, WMFSpacing.medium)
            .padding(.bottom, listBottomPadding)
        }
    }

    // In a regular width the sheet floats with rounded bottom corners and no safe area below
    // the content, so the last card needs more room to clear the corners.
    private var listBottomPadding: CGFloat {
        horizontalSizeClass == .regular ? WMFSpacing.xxLarge : WMFSpacing.large
    }

    private var emptyState: some View {
        VStack(spacing: WMFSpacing.small) {
            if let illustration = UIImage(named: "semantic-search-empty", in: Bundle.module, compatibleWith: nil) {
                Image(uiImage: illustration)
                    .accessibilityHidden(true)
            }
            Text(viewModel.emptyTitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundStyle(Color(theme.text))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, WMFSpacing.large)
    }
}

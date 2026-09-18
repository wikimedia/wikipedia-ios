import SwiftUI

public struct WMFSearchResultsView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSearchResultsViewModel
    @AccessibilityFocusState private var focusedElementID: String?

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFSearchResultsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(theme.paperBackground)
                .ignoresSafeArea()
            if let emptyState = viewModel.emptyState {
                WMFEmptyView(viewModel: emptyViewModel(for: emptyState), type: .noItems, isScrollable: true)
                    .padding(.top, viewModel.topPadding)
            } else {
                resultsList
            }
        }
    }

    private func emptyViewModel(for state: WMFSearchResultsViewModel.EmptyState) -> WMFEmptyViewModel {
        switch state {
        case .noResults:
            return WMFEmptyViewModel(
                localizedStrings: WMFEmptyViewModel.LocalizedStrings(title: viewModel.localizedStrings.noResultsMessage, subtitle: "", titleFilter: nil, buttonTitle: nil, attributedFilterString: nil),
                image: nil,
                imageColor: nil,
                numberOfFilters: nil)
        case .noInternetConnection:
            return WMFEmptyViewModel(
                localizedStrings: WMFEmptyViewModel.LocalizedStrings(title: viewModel.localizedStrings.noInternetConnectionTitle, subtitle: "", titleFilter: nil, buttonTitle: nil, attributedFilterString: nil),
                image: viewModel.noInternetConnectionImage,
                imageColor: appEnvironment.theme.secondaryText,
                numberOfFilters: nil,
                imageSize: nil)
        }
    }

    private var resultsList: some View {
        List {
            if let entryPointViewModel = viewModel.entryPointViewModel {
                WMFSemanticSearchEntryPointView(viewModel: entryPointViewModel, horizontalPadding: viewModel.horizontalPadding)
                    .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(theme.paperBackground))
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchEntryPoint)
                    .accessibilityFocused($focusedElementID, equals: WMFSearchResultsViewModel.entryPointAccessibilityID)
            }
            ForEach(viewModel.results) { result in
                WMFSearchResultRow(viewModel: viewModel, result: result, focusedElementID: $focusedElementID)
            }
        }
        .listStyle(.plain)
        .onChange(of: viewModel.accessibilityFocusRequestID) { _, _ in
            focusedElementID = viewModel.firstAccessibilityElementID
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.never)
        .contentMargins(.top, viewModel.topPadding, for: .scrollContent)
    }
}

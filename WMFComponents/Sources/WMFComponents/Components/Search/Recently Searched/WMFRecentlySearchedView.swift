import SwiftUI

public struct WMFRecentlySearchedView: View {

    @ObservedObject var viewModel: WMFRecentlySearchedViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFRecentlySearchedViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {

                if viewModel.recentSearchTerms.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                        Text(viewModel.localizedStrings.noSearches)
                            .font(Font(WMFFont.for(.callout)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                } else {
                    HStack {
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                        Spacer()
                        Button(viewModel.localizedStrings.clearAll) {
                            viewModel.deleteAllAction()
                        }
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.link))
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }

                List {
                    if !viewModel.recentSearchTerms.isEmpty {
                        ForEach(Array(viewModel.displayedSearchTerms.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                Text(item.text)
                                    .font(Font(WMFFont.for(.body)))
                                    .foregroundStyle(Color(uiColor: theme.text))
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .background(Color(theme.paperBackground))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectAction(item)
                            }
                            .swipeActions {
                                Button {
                                    viewModel.deleteItemAction(index)
                                } label: {
                                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .trash) ?? UIImage())
                                        .accessibilityLabel(viewModel.localizedStrings.deleteActionAccessibilityLabel)
                                }
                                .tint(Color(theme.destructive))
                                .labelStyle(.iconOnly)
                            }
                            .listRowBackground(Color(theme.paperBackground))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(viewModel.needsAttachedView)
                .frame(height: CGFloat(viewModel.displayedSearchTerms.count) * 44)

                if viewModel.needsAttachedView && viewModel.tabsDataController.getViewTypeForExperiment == .becauseYouRead,
                   let becauseVM = viewModel.becauseYouReadViewModel {
                    WMFBecauseYouReadView(viewModel: becauseVM)
                } else if viewModel.needsAttachedView && viewModel.tabsDataController.getViewTypeForExperiment == .didYouKnow {
                    Text("Did you know")
                }
            }
        }
        .background(Color(theme.paperBackground))
        .padding(.top, viewModel.topPadding)
    }
}

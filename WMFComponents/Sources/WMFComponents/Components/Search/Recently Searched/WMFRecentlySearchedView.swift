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
        VStack(spacing: 0) {
            if viewModel.recentSearchTerms.isEmpty {
                VStack(alignment: .leading) {
                    Text(viewModel.localizedStrings.noSearches)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .multilineTextAlignment(.leading)
                        .padding(16)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    Text(viewModel.localizedStrings.title)
                        .font(Font(WMFFont.for(.boldHeadline)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                    Spacer()
                    if !viewModel.recentSearchTerms.isEmpty {
                        Button(viewModel.localizedStrings.clearAll) {
                            viewModel.deleteAllAction()
                        }
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.link))
                    }
                }
                .padding()
                List {
                    ForEach(Array(viewModel.displayedSearchTerms.enumerated()),
                            id: \.element.id) { index, item in
                        HStack {
                            Text(item.text)
                                .font(Font(WMFFont.for(.body)))
                                .foregroundStyle(Color(uiColor: theme.secondaryText))
                            Spacer()
                        }
                        .padding(.vertical, 8)
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

                    }
                    if viewModel.tabsDataController.getViewTypeForExperiment == .becauseYouRead, let becauseVM = viewModel.becauseYouReadViewModel {
                        WMFBecauseYouReadView(viewModel: becauseVM)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden, edges: .all)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Color.clear)     
                    } else if viewModel.tabsDataController.getViewTypeForExperiment == .didYouKnow {
                        Text("Did you know")
                    }
                }
                .listStyle(.plain)
            }

        }
        .background(Color(theme.paperBackground))
        .padding(.top, viewModel.topPadding)
    }
}

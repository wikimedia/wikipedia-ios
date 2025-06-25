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
        if viewModel.recentSearchTerms.isEmpty {
            Text(viewModel.localizedStrings.noSearches)
                .font(Font(WMFFont.for(.callout)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .padding([.top], viewModel.topPadding)
        } else {
            HStack {
                Text(viewModel.localizedStrings.title)
                    .font(Font(WMFFont.for(.boldHeadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                Spacer()
                if !viewModel.recentSearchTerms.isEmpty {
                    Button(viewModel.localizedStrings.clearAll) {
                        viewModel.clearAll() // update view etc etc, maybe a task
                    }
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.link))
                }
            }
            .padding()

            List {
                ForEach(viewModel.recentSearchTerms) { item in
                    Text(item.text)
                        .swipeActions {
                            Button("Delete") {
                                print("Delete recent search term")
                            }
                        }
                }
            }
            .listStyle(.grouped)
            .padding([.top], viewModel.topPadding)
        }
        
    }
}

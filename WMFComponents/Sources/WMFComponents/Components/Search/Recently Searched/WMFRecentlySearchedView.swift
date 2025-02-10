import SwiftUI

public struct WMFRecentlySearchedView: View {
    
    @ObservedObject var viewModel: WMFRecentlySearchedViewModel
    
    public init(viewModel: WMFRecentlySearchedViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        if viewModel.recentSearchTerms.isEmpty {
            Text("No recent searches yet")
                .padding([.top], viewModel.topPadding)
        } else {
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

import SwiftUI

public struct WMFTabsView: View {
    @ObservedObject var viewModel: WMFTabsViewModel
    
    private let adaptiveColumn = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    public init(viewModel: WMFTabsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        
        ScrollView {
            LazyVGrid(columns: adaptiveColumn, spacing: 20) {
                ForEach(viewModel.tabViewModels) { tabViewModel in
                    Text(String(tabViewModel.topArticleTitle))
                        .frame(width: 150, height: 150, alignment: .center)
                        .background(.gray)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.title)
                        .onTapGesture {
                            viewModel.tappedTabAction(tabViewModel.tab)
                        }
                }
            }
            
        }
        .padding()
        .onAppear {
            viewModel.fetchTabs()
        }
    }
}

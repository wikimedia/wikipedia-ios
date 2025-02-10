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
                    ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.3))
                                    .onTapGesture {
                                        viewModel.tappedTabAction(tabViewModel.tab)
                                    }
                                
                                VStack {
                                    Spacer()
                                    Text(tabViewModel.topArticleTitle)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .lineLimit(3)
                                    Spacer()
                                }
                                
                                Button(action: {
                                    viewModel.tappedCloseTabAction(tabViewModel.tab)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.black)
                                        .padding(5)
                                }
                            }
                            .frame(width: 150, height: 150)
                    
                }
            }
            
        }
        .padding()
        .onAppear {
            viewModel.fetchTabs()
        }
    }
}

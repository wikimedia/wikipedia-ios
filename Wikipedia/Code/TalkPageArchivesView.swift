import SwiftUI

struct TalkPageArchivesView: View {
    
    @ObservedObject var viewModel: TalkPageArchivesViewModel
    @SwiftUI.State private var task: Task<Void, Never>?
    
    var didTapItem: (TalkPageArchivesViewModel.Item) -> Void = { _ in }
    
    var body: some View {
        TrackingScrollView(
            axes: [.vertical],
            showsIndicators: true
        ) {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.items, id: \.pageID) { item in
                    Text(item.displayTitle)
                        .onTapGesture {
                            didTapItem(item)
                        }
                }
            }
        }
        .onAppear {
            task = Task(priority: .userInitiated) {
                await viewModel.fetchArchives()
            }
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
    }
}

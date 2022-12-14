import SwiftUI

struct TalkPageArchivesView: View {
    
    @ObservedObject var data: CustomNavigationViewData
    
    var body: some View {
        TrackingScrollView(
            axes: [.vertical],
            showsIndicators: true
        ) {
            LazyVStack(alignment: .leading) {
                ForEach(0..<100) { i in
                    Text("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.")
                }
            }
            .padding(.top, data.totalHeight)
        }
        .environmentObject(data)
    }
}

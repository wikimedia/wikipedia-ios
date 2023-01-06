import SwiftUI
import WMF

struct TalkPageArchivesView: View {
    
    @EnvironmentObject var observableTheme: ObservableTheme
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach((1...100), id: \.self) {
                   Text("\($0)")
                        .foregroundColor(Color(observableTheme.theme.colors.primaryText))
               }
            }
        }
        .background(Color(observableTheme.theme.colors.paperBackground))
    }
}

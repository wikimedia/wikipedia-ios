import SwiftUI

struct LongTestingListView: View {
    var body: some View {
        VStack {
            ForEach((1...500), id: \.self) {
                    Text("\($0)…")
                }
        }
       
    }
}

struct LongTestingListView_Previews: PreviewProvider {
    static var previews: some View {
        LongTestingListView()
    }
}

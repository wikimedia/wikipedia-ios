import SwiftUI

public struct WMFNewArticleTabView: View {

    let viewModel: WMFNewArticleTabViewModel

    public init(viewModel: WMFNewArticleTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        if let dyk = viewModel.dyk {
            WMFNewArticleTabViewDidYouKnow(
                dyk: dyk,
                fromSource: "from English Wikipedia"
            )
            .padding()
        } else {
            Text("Loading...")
        }
    }
}

import SwiftUI

public struct WMFNewArticleTabView: View {

    let viewModel: WMFNewArticleTabViewModel

    public init(viewModel: WMFNewArticleTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        WMFNewArticleTabViewDidYouKnow(
            dyk: viewModel.dyk,
            fromSource: "from English Wikipedia"
        )
        .padding()
    }
}

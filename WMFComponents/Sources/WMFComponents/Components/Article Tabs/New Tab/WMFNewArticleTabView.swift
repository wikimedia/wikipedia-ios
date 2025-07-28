import SwiftUI

public struct WMFNewArticleTabView: View {
    @ObservedObject var viewModel: WMFNewArticleTabViewModel

    public init(viewModel: WMFNewArticleTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading Did You Know…")
        } else if let dyk = viewModel.dyk {
            WMFNewArticleTabViewDidYouKnow(dyk: dyk, fromSource: viewModel.dykLocalizedStrings?.fromSource ?? viewModel.fromSourceDefault)
        }
    }
}

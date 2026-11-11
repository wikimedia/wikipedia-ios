import SwiftUI

public struct WMFWikiRunView: View {

    @ObservedObject private var viewModel: WMFWikiRunViewModel

    public init(viewModel: WMFWikiRunViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        WMFWikiRunWebView(viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
    }
}

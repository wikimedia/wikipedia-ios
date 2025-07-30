import SwiftUI

public struct WMFNewArticleTabView: View {
    @ObservedObject var viewModel: WMFNewArticleTabViewModel

    public init(viewModel: WMFNewArticleTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Text("")
    }
}

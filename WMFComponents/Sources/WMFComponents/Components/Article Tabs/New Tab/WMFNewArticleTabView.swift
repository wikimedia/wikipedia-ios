import SwiftUI

public struct WMFNewArticleTabView: View {

    let viewModel: WMFNewArticleTabViewModel

    public init(viewModel: WMFNewArticleTabViewModel) {
        self.viewModel = viewModel
    }
    public var body: some View {
        WMFNewArticleTabViewDidYouKnow(
            dykTitle: "Did you know...",
            funFact: "that a <a href=\"https://en.wikipedia.org\">15-second commercial for a streaming service</a> has been blamed for causing arguments and domestic violence?",
            fromSource: "from English Wikipedia"
        )
        .padding()
    }
}

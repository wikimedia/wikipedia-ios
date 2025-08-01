import SwiftUI

public struct WMFNewArticleTabViewDidYouKnow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFNewArticleTabDidYouKnowViewModel
    weak var linkDelegate: UITextViewDelegate?
    
    public init(viewModel: WMFNewArticleTabDidYouKnowViewModel, linkDelegate: UITextViewDelegate?) {
        self.viewModel = viewModel
        self.linkDelegate = linkDelegate
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextViewWrapper(
                text: viewModel.dyk ?? "",
                linkDelegate: linkDelegate)
            Text(viewModel.fromSource)
                .font(Font.for(.caption1))
                .foregroundStyle(Color(theme.text))
        }
        .background(Color(theme.midBackground))
    }
}

import SwiftUI

public struct WMFNewArticleTabViewDidYouKnow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFNewArticleTabDidYouKnowViewModel
    @State private var textViewHeight: CGFloat = 0
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
                text: viewModel.didYouKnowFact ?? "",
                linkDelegate: linkDelegate,
                dynamicHeight: $textViewHeight
            )
            .frame(height: textViewHeight)

            Text(viewModel.fromSource)
                .font(Font.for(.caption1))
                .foregroundStyle(Color(theme.text))
            Spacer()
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(Color(theme.midBackground))
        .frame(maxHeight: .infinity)
    }
}

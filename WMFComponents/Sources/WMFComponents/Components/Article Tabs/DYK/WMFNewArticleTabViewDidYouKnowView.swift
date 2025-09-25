import SwiftUI

public struct WMFNewArticleTabViewDidYouKnowView: View {
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

    // Todo: limit dynamic type sizes
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .questionMarkBubble) ?? UIImage())
                Text(viewModel.dykLocalizedStrings.didYouKnowTitle)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(theme.text))
            }

            TextViewWrapper(
                text: viewModel.didYouKnowFact ?? "",
                linkDelegate: linkDelegate,
                dynamicHeight: $textViewHeight,
                maxLines: 3
            )
            .frame(height: textViewHeight)

            Text(viewModel.fromSource)
                .font(Font.for(.caption1))
                .foregroundStyle(Color(theme.secondaryText))
        }
        .padding(16)
        .background(Color(theme.midBackground))
        .frame(maxHeight: .infinity)
    }
}

import SwiftUI

public struct WMFTabsOverviewDidYouKnowView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTabsOverviewDidYouKnowViewModel
    @State private var textViewHeight: CGFloat = 0
    weak var linkDelegate: UITextViewDelegate?
    
    public init(viewModel: WMFTabsOverviewDidYouKnowViewModel, linkDelegate: UITextViewDelegate?) {
        self.viewModel = viewModel
        self.linkDelegate = linkDelegate
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let image = WMFSFSymbolIcon.for(symbol: .questionMarkBubble, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
                    Image(uiImage: image)
                }
                Text(viewModel.dykLocalizedStrings.didYouKnowTitle)
                    .font(WMFSwiftUIFont.font(.mediumSubheadline))
                    .foregroundStyle(Color(theme.text))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }

            TextViewWrapper(
                text: viewModel.didYouKnowFact ?? "",
                linkDelegate: linkDelegate,
                dynamicHeight: $textViewHeight,
                maxLines: 3
            )
            .frame(height: textViewHeight)

            Text(viewModel.fromSource)
                .font(WMFSwiftUIFont.font(.caption1))
                .foregroundStyle(Color(theme.secondaryText))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(16)
        .background(Color(theme.midBackground))
        .frame(maxHeight: .infinity)
    }
}

import SwiftUI

public struct WMFTabsOverviewDidYouKnowView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTabsOverviewDidYouKnowViewModel
    
    public init(viewModel: WMFTabsOverviewDidYouKnowViewModel) {
        self.viewModel = viewModel
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var attributedText: AttributedString {
        
        let traitCollection = appEnvironment.traitCollection
        
        let normalFont = wmfScaledCappedFont(wmfStyle: .subheadline, textStyle: .subheadline, trait: traitCollection, maxPointSize: 21)
        let boldFont = wmfScaledCappedFont(wmfStyle: .boldSubheadline,textStyle: .subheadline, trait: traitCollection, maxPointSize: 21)
        let italicsFont = wmfScaledCappedFont(wmfStyle: .italicSubheadline,textStyle: .subheadline, trait: traitCollection, maxPointSize: 21)
        let boldItalicsFont = wmfScaledCappedFont(wmfStyle: .boldItalicSubheadline, textStyle: .subheadline, trait: traitCollection, maxPointSize: 21)

        let styles = HtmlUtils.Styles(
            font: normalFont,
            boldFont: boldFont,
            italicsFont: italicsFont,
            boldItalicsFont: boldItalicsFont,
            color: theme.text,
            linkColor: theme.link,
            lineSpacing: 3
        )
        let text = viewModel.didYouKnowFact ?? ""
        return (try? HtmlUtils.attributedStringFromHtml(viewModel.didYouKnowFact ?? "", styles: styles)) ?? AttributedString(text)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let image = WMFSFSymbolIcon.for(symbol: .questionMarkBubble, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
                    Image(uiImage: image)
                }
                Text(viewModel.dykLocalizedStrings.didYouKnowTitle)
                    .font(WMFSwiftUIFont.font(.boldSubheadline))
                    .foregroundStyle(Color(theme.text))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            
            Text(attributedText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    viewModel.tappedLinkAction(url)
                    return .handled
                 })

            Text(viewModel.fromSource)
                .font(WMFSwiftUIFont.font(.caption1))
                .foregroundStyle(Color(theme.secondaryText))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(16)
        .background(Color(theme.midBackground))
        .frame(maxWidth: .infinity)
    }
    
    // Limiting font size with WMFFont's compatibleWith: UITraitCollection(preferredContentSizeCategory: ...) wasn't effective
    fileprivate func wmfScaledCappedFont(wmfStyle: WMFFont, textStyle: UIFont.TextStyle, trait: UITraitCollection, maxPointSize: CGFloat) -> UIFont {
        let base = WMFFont.for(wmfStyle, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let scaledPoint = UIFontMetrics(forTextStyle: textStyle)
            .scaledValue(for: base.pointSize, compatibleWith: trait)
        return base.withSize(min(scaledPoint, maxPointSize))
    }
}


//
// public struct WMFTabsOverviewDidYouKnowView: View {
//    @ObservedObject var appEnvironment = WMFAppEnvironment.current
//    @ObservedObject var viewModel: WMFTabsOverviewDidYouKnowViewModel
//    @State private var textViewHeight: CGFloat = 0
//    weak var linkDelegate: UITextViewDelegate?
//    
//    public init(viewModel: WMFTabsOverviewDidYouKnowViewModel, linkDelegate: UITextViewDelegate?) {
//        self.viewModel = viewModel
//        self.linkDelegate = linkDelegate
//    }
//
//    var theme: WMFTheme {
//        return appEnvironment.theme
//    }
//
//    public var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(spacing: 8) {
//                if let image = WMFSFSymbolIcon.for(symbol: .questionMarkBubble, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
//                    Image(uiImage: image)
//                }
//                Text(viewModel.dykLocalizedStrings.didYouKnowTitle)
//                    .font(WMFSwiftUIFont.font(.mediumSubheadline))
//                    .foregroundStyle(Color(theme.text))
//                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//            }
//
//            TextViewWrapper(
//                text: viewModel.didYouKnowFact ?? "",
//                linkDelegate: linkDelegate,
//                dynamicHeight: $textViewHeight,
//                maxLines: 3
//            )
//            .frame(height: textViewHeight)
//
//            Text(viewModel.fromSource)
//                .font(WMFSwiftUIFont.font(.caption1))
//                .foregroundStyle(Color(theme.secondaryText))
//                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//        }
//        .padding(16)
//        .background(Color(theme.midBackground))
//        .frame(maxHeight: .infinity)
//    }
// }

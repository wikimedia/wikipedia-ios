import SwiftUI

public struct WMFNewArticleTabViewDidYouKnow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFNewArticleTabDidYouKnowViewModel
    
    public init(viewModel: WMFNewArticleTabDidYouKnowViewModel) {
        self.viewModel = viewModel
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var attributedString: AttributedString {
        return (try? HtmlUtils.attributedStringFromHtml(viewModel.dyk ?? "", styles: styles)) ?? AttributedString(viewModel.dyk ?? "")
    }
    
    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(attributedString)
            Text(viewModel.fromSource)
                .font(Font.for(.caption1))
                .foregroundStyle(Color(theme.text))
        }
        .background(Color(theme.midBackground))
        .frame(maxWidth: .infinity)
    }
}

// struct WMFNewArticleTabViewDidYouKnow_Previews: PreviewProvider {
//    static var previews: some View {
//        WMFNewArticleTabViewDidYouKnow(
//            dykTitle: "Did you know...",
//            funFact: "that a <a href=\"https://en.wikipedia.org\">15-second commercial for a streaming service</a> has been blamed for causing arguments and domestic violence?",
//            fromSource: "from English Wikipedia"
//        )
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
// }


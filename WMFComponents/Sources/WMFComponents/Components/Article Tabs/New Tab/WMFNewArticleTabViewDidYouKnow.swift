import SwiftUI

public struct WMFNewArticleTabViewDidYouKnow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let dykTitle: String
    let funFact: String
    let fromSource: String
    
    private var attributedString: AttributedString {
        return (try? HtmlUtils.attributedStringFromHtml(funFact, styles: styles)) ?? AttributedString(funFact)
    }
    
    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dykTitle)
                .font(Font.for(.boldSubheadline))
                .foregroundStyle(Color(theme.secondaryText))
                // .frame(maxWidth: .infinity, alignment: .center)
            Text(attributedString)
            Text(fromSource)
                .font(Font.for(.caption1))
                .foregroundStyle(Color(theme.text))
        }
        .frame(maxWidth: .infinity)
    }
}

struct WMFNewArticleTabViewDidYouKnow_Previews: PreviewProvider {
    static var previews: some View {
        WMFNewArticleTabViewDidYouKnow(
            dykTitle: "Did you know...",
            funFact: "that a <a href=\"https://en.wikipedia.org\">15-second commercial for a streaming service</a> has been blamed for causing arguments and domestic violence?",
            fromSource: "from English Wikipedia"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}


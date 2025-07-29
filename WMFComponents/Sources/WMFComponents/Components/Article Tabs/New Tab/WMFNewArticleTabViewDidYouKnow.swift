import SwiftUI

public struct WMFNewArticleTabViewDidYouKnow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let dyk: String
    let fromSource: String
    let tappedURLAction: (URL?) -> Void
    
    private var attributedString: AttributedString {
        return (try? HtmlUtils.attributedStringFromHtml(dyk, styles: styles)) ?? AttributedString(dyk)
    }
    
    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(attributedString)
                .environment(\.openURL, OpenURLAction { url in
                    
                    var components = url.pathComponents
                    // remove relative bit?
                    components = components.filter { $0 != "." }
                    
                    var finalComponents = URLComponents()
                    finalComponents.scheme = "https"
                    finalComponents.host = "en.wikipedia.org"
                    finalComponents.path = "/wiki/" + components.joined(separator: "/")
                    let finalURL = finalComponents.url
      
                    tappedURLAction(finalURL)
                    
                    return .handled
                })
            Text(fromSource)
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


import SwiftUI
import WKData

struct WKArticleSummaryView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    let articleSummary: WKArticleSummary
    
    private var theme: WKTheme {
        return appEnvironment.theme
    }
    
    private var titleAttributedString: AttributedString {
        let styles = HtmlUtils.Styles(font: WKFont.for(.georgiaHeadline), boldFont: WKFont.for(.boldGeorgiaHeadline), italicsFont: WKFont.for(.italicsGeorgiaHeadline), boldItalicsFont: WKFont.for(.boldItalicsGeorgiaHeadline), color: theme.text, linkColor: theme.link)
        return (try? HtmlUtils.attributedStringFromHtml(articleSummary.displayTitle, styles: styles)) ?? AttributedString(articleSummary.displayTitle)
    }
    
    private var summaryAttributedString: AttributedString {
        let styles = HtmlUtils.Styles(font: WKFont.for(.callout), boldFont: WKFont.for(.boldCallout), italicsFont: WKFont.for(.italicsCallout), boldItalicsFont: WKFont.for(.boldItalicsCallout), color: theme.text, linkColor: theme.link)
        return (try? HtmlUtils.attributedStringFromHtml(articleSummary.extractHtml, styles: styles)) ?? AttributedString(articleSummary.extractHtml)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
                .frame(height: 12)
            Text(titleAttributedString)
            
            if let description = articleSummary.description {
                Text(description)
                    .font(Font(WKFont.for(.subheadline)))
                    .foregroundStyle(Color(theme.secondaryText))
            }
            
            Spacer()
                .frame(height: 2)
            HStack {
                Rectangle()
                    .foregroundStyle(Color(theme.newBorder))
                    .frame(width: 60, height: 0.5)
                Spacer()
            }
            
            Spacer()
                .frame(height: 2)
            Text(summaryAttributedString)
                .lineLimit(nil)
                .lineSpacing(3)
        }
        .padding([.leading, .trailing, .bottom])
    }
}

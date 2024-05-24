import SwiftUI
import WKData

struct WKArticleSummaryView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    @EnvironmentObject var tooltipGeometryValues: WKTooltipGeometryValues
    
    let articleSummary: WKArticleSummary
    
    private var theme: WKTheme {
        return appEnvironment.theme
    }
    
    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WKFont.for(.georgiaHeadline), boldFont: WKFont.for(.boldGeorgiaHeadline), italicsFont: WKFont.for(.italicsGeorgiaHeadline), boldItalicsFont: WKFont.for(.boldItalicsGeorgiaHeadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    private var summaryStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WKFont.for(.callout), boldFont: WKFont.for(.boldCallout), italicsFont: WKFont.for(.italicsCallout), boldItalicsFont: WKFont.for(.boldItalicsCallout), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
                .frame(height: 12)
            WKHtmlText(html: articleSummary.displayTitle, styles: titleStyles)
            
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
                        .background(content: {
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let insideFrame = geometry.frame(in: .global)
                                        tooltipGeometryValues.articleSummaryDivGlobalFrame = insideFrame
                                    }
                            }
                        })
                Spacer()
            }
            Spacer()
                .frame(height: 2)
            WKHtmlText(html: articleSummary.extractHtml, styles: summaryStyles)
        }
    }


}

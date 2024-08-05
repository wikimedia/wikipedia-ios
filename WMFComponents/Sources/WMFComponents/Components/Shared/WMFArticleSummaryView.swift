import SwiftUI
import WMFData

struct WMFArticleSummaryView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @EnvironmentObject var tooltipGeometryValues: WMFTooltipGeometryValues
    
    let articleSummary: WMFArticleSummary
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.georgiaTitle1), boldFont: WMFFont.for(.boldGeorgiaTitle1), italicsFont: WMFFont.for(.italicGeorgiaTitle1), boldItalicsFont: WMFFont.for(.boldItalicGeorgiaTitle1), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    private var summaryStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.callout), boldFont: WMFFont.for(.boldCallout), italicsFont: WMFFont.for(.italicCallout), boldItalicsFont: WMFFont.for(.boldItalicCallout), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
                .frame(height: 12)
            WMFHtmlText(html: articleSummary.displayTitle, styles: titleStyles)
            
            if let description = articleSummary.description {
                Text(description)
                    .font(Font(WMFFont.for(.subheadline)))
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
            WMFHtmlText(html: articleSummary.extractHtml, styles: summaryStyles)
        }
    }


}

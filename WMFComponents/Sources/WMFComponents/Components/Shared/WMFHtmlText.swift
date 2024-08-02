import SwiftUI

struct WMFHtmlText: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let html: String
    let styles: HtmlUtils.Styles
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var attributedString: AttributedString {
        
        return (try? HtmlUtils.attributedStringFromHtml(html, styles: styles)) ?? AttributedString(html)
    }
    
    var body: some View {
        Text(attributedString)
            .lineLimit(nil)
            .lineSpacing(styles.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }
}

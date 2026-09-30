import SwiftUI

struct WMFHtmlText: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let html: String
    let styles: HtmlUtils.Styles
    var lineLimit: Int? = nil

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private var attributedString: AttributedString {
        return (try? HtmlUtils.attributedStringFromHtml(html, styles: styles)) ?? AttributedString(html)
    }

    var body: some View {
        if let lineLimit {
            // Clamped: truncates within height-constrained containers (fixed-size cards)
            Text(attributedString)
                .lineSpacing(styles.lineSpacing)
                .lineLimit(lineLimit)
        } else {
            // Unclamped: takes full ideal height (masonry grid cards, prose)
            Text(attributedString)
                .lineSpacing(styles.lineSpacing)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

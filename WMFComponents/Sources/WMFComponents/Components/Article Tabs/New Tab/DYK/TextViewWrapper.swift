import UIKit
import SwiftUI

public struct TextViewWrapper: UIViewRepresentable {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let text: String
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    weak var linkDelegate: UITextViewDelegate?

    public func makeUIView(context: Context) -> SwiftUILinkDetectingTextView {
        let textView = SwiftUILinkDetectingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.attributedText = NSAttributedString(string: text)
        textView.apply(theme: theme)
        textView.dataDetectorTypes = []
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = linkDelegate
        return textView
    }

    public func updateUIView(_ uiView: SwiftUILinkDetectingTextView, context: Context) {
        let styles = HtmlUtils.Styles(
            font: WMFFont.for(.subheadline),
            boldFont: WMFFont.for(.boldSubheadline),
            italicsFont: WMFFont.for(.italicSubheadline),
            boldItalicsFont: WMFFont.for(.boldItalicSubheadline),
            color: theme.text,
            linkColor: theme.link,
            lineSpacing: 3
        )
        let attributed = (try? HtmlUtils.nsAttributedStringFromHtml(text, styles: styles)) ?? NSAttributedString(string: text)
        uiView.attributedText = attributed
    }
}

public class SwiftUILinkDetectingTextView: UITextView {
    private var currentTheme = WMFAppEnvironment.current.theme

    func apply(theme: WMFTheme) {
        currentTheme = theme
        backgroundColor = theme.paperBackground
        textColor = theme.text
        keyboardAppearance = theme.keyboardAppearance
        tintColor = theme.link
    }
}

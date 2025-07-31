import SwiftUI
import UIKit

public struct TextViewWrapper: UIViewRepresentable {
    let text: String
    let theme: WMFTheme
    weak var delegate: UITextViewDelegate?

    @Binding var dynamicHeight: CGFloat

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.dataDetectorTypes = [.link]
        textView.delegate = delegate
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.linkTextAttributes = [.foregroundColor: theme.link]
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
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

        DispatchQueue.main.async {
            let size = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude))
            if self.dynamicHeight != size.height {
                self.dynamicHeight = size.height
            }
        }
    }
}

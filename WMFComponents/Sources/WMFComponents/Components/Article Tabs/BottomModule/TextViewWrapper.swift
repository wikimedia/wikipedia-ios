import UIKit
import SwiftUI

public struct TextViewWrapper: UIViewRepresentable {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let text: String
    weak var linkDelegate: UITextViewDelegate?

    @Binding var dynamicHeight: CGFloat

    var maxLines: Int? = nil
    var truncation: NSLineBreakMode = .byTruncatingTail

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.delegate = linkDelegate
        textView.textContainer.lineBreakMode = truncation
        textView.textContainerInset = .zero
        textView.textContainer.maximumNumberOfLines = maxLines ?? 0
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.textContainer.lineBreakMode = truncation
        uiView.textContainer.maximumNumberOfLines = maxLines ?? 0

        let trait = uiView.traitCollection

        let normalFont = wmfScaledCappedFont(wmfStyle: .subheadline, textStyle: .subheadline, trait: trait, maxPointSize: 21)
        let boldFont = wmfScaledCappedFont(wmfStyle: .boldSubheadline,textStyle: .subheadline, trait: trait, maxPointSize: 21)
        let italicsFont = wmfScaledCappedFont(wmfStyle: .italicSubheadline,textStyle: .subheadline, trait: trait, maxPointSize: 21)
        let boldItalicsFont = wmfScaledCappedFont(wmfStyle: .boldItalicSubheadline, textStyle: .subheadline, trait: trait, maxPointSize: 21)

        let styles = HtmlUtils.Styles(
            font: normalFont,
            boldFont: boldFont,
            italicsFont: italicsFont,
            boldItalicsFont: boldItalicsFont,
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

    // Limiting font size with WMFFont's compatibleWith: UITraitCollection(preferredContentSizeCategory: ...) wasn't effective
    fileprivate func wmfScaledCappedFont(wmfStyle: WMFFont, textStyle: UIFont.TextStyle, trait: UITraitCollection, maxPointSize: CGFloat) -> UIFont {
        let base = WMFFont.for(wmfStyle, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let scaledPoint = UIFontMetrics(forTextStyle: textStyle)
            .scaledValue(for: base.pointSize, compatibleWith: trait)
        return base.withSize(min(scaledPoint, maxPointSize))
    }
}

public class SwiftUILinkDetectingTextView: UITextView {
    private var currentTheme = WMFAppEnvironment.current.theme

    public override var intrinsicContentSize: CGSize {
        let size = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let fittingSize = sizeThatFits(size)
        return CGSize(width: UIView.noIntrinsicMetric, height: fittingSize.height)
    }

    public func apply(theme: WMFTheme) {
        currentTheme = theme
        backgroundColor = theme.paperBackground
        textColor = theme.text
        keyboardAppearance = theme.keyboardAppearance
        tintColor = theme.link
    }
}


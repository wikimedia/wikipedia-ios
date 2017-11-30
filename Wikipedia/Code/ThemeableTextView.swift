import UIKit
import WMF

@objc(WMFThemeableTextView)
class ThemeableTextView: SetupView {
    
    fileprivate let textView = UITextView()
    fileprivate let underlineView = UIView()
    fileprivate let underlineHeight: CGFloat = 1
    
    override open func setup() {
        super.setup()
        
        textView.delegate = self
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        
        wmf_addSubview(textView, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 0, left: 0, bottom: underlineHeight, right: 0))
        addSubview(underlineView)
        
        let leadingConstraint = leadingAnchor.constraint(equalTo: underlineView.leadingAnchor)
        let trailingConstraint = trailingAnchor.constraint(equalTo: underlineView.trailingAnchor)
        let heightConstraint = underlineView.heightAnchor.constraint(equalToConstant: underlineHeight)
        let bottomConstraint = bottomAnchor.constraint(equalTo: underlineView.bottomAnchor)
        addConstraints([leadingConstraint, trailingConstraint, bottomConstraint])
        underlineView.addConstraint(heightConstraint)
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: textView.contentSize.height + underlineHeight)
    }
    
    var text: String {
        return textView.text
    }

}

extension ThemeableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        invalidateIntrinsicContentSize()
    }
}

extension ThemeableTextView: Themeable {
    func apply(theme: Theme) {
        underlineView.backgroundColor = theme.colors.border
        textView.backgroundColor = theme.colors.paperBackground
        textView.textColor = theme.colors.primaryText
        backgroundColor = theme.colors.paperBackground
    }
}

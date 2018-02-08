import UIKit
import WMF

public protocol ThemeableTextViewDelegate: NSObjectProtocol {
    func textViewDidChange(_ textView: UITextView)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
}

@objc(WMFThemeableTextView)
class ThemeableTextView: SetupView {
    
    let textView = UITextView()
    fileprivate let underlineView = UIView()
    fileprivate let underlineHeight: CGFloat = 1
    fileprivate let clearButton = UIButton()
    public weak var delegate: ThemeableTextViewDelegate?
    
    var showsClearButton: Bool = false
    
    override open func setup() {
        super.setup()
        
        textView.delegate = self
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setImage(UIImage(named: "clear-mini"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        addSubview(clearButton)
        clearButton.isHidden = true
        let clearButtonWidthConstraint = clearButton.widthAnchor.constraint(equalToConstant: 32)
        clearButton.addConstraints([clearButtonWidthConstraint])
        
        wmf_addSubview(textView, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 0, left: 0, bottom: underlineHeight, right: clearButtonWidthConstraint.constant - 8))
        addSubview(underlineView)
        
        let leadingConstraint = leadingAnchor.constraint(equalTo: underlineView.leadingAnchor)
        let trailingConstraint = trailingAnchor.constraint(equalTo: underlineView.trailingAnchor)
        let heightConstraint = underlineView.heightAnchor.constraint(equalToConstant: underlineHeight)
        let bottomConstraint = bottomAnchor.constraint(equalTo: underlineView.bottomAnchor)
        let centerYConstraint = clearButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor)
        let clearButtonTrailingConstraint = clearButton.trailingAnchor.constraint(equalTo: trailingAnchor)

        addConstraints([leadingConstraint, trailingConstraint, bottomConstraint, clearButtonTrailingConstraint])
        underlineView.addConstraint(heightConstraint)
        
        centerYConstraint.isActive = true
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: textView.contentSize.height + underlineHeight)
    }
    
    fileprivate func updateClearButton() {
        clearButton.isHidden = showsClearButton ? textView.text.isEmpty : true
    }
    
    @objc fileprivate func clearButtonPressed() {
        textView.text = ""
        textViewDidChange(textView)
    }

}

extension ThemeableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        invalidateIntrinsicContentSize()
        updateClearButton()
        delegate?.textViewDidChange(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        clearButton.isHidden = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateClearButton()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return delegate?.textView(textView, shouldChangeTextIn: range, replacementText: text) ?? false
    }
}

extension ThemeableTextView: Themeable {
    func apply(theme: Theme) {
        underlineView.backgroundColor = theme.colors.border
        textView.backgroundColor = theme.colors.paperBackground
        textView.textColor = theme.colors.primaryText
        backgroundColor = theme.colors.paperBackground
        clearButton.tintColor = theme.colors.secondaryText
    }
}

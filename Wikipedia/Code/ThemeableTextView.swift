protocol ThemeableTextViewPlaceholderDelegate: AnyObject {
    func themeableTextViewPlaceholderDidHide(_ themeableTextView: UITextView, isPlaceholderHidden: Bool)
}

protocol ThemeableTextViewClearDelegate: AnyObject {
    func themeableTextViewDidClear(_ themeableTextView: UITextView)
}

class ThemeableTextView: UITextView {
    private var theme = Theme.standard
    public var isUnderlined = true
    private var firstTimeEditing = true

    weak var _delegate: UITextViewDelegate?
    weak var placeholderDelegate: ThemeableTextViewPlaceholderDelegate?
    weak var clearDelegate: ThemeableTextViewClearDelegate?

    var clearButton: UIButton?
    var showsClearButton: Bool = false {
        didSet {
            if showsClearButton {
                let image = #imageLiteral(resourceName: "clear-mini")
                let clearButton = UIButton(frame: CGRect(origin: .zero, size: image.size))
                clearButton.setImage(image, for: .normal)
                clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
                clearButton.isAccessibilityElement = true
                clearButton.accessibilityLabel = CommonStrings.accessibilityClearTitle
                addSubview(clearButton)
                clearButton.isHidden = true
                var inset = textContainerInset
                if effectiveUserInterfaceLayoutDirection == .rightToLeft {
                    inset.left += clearButton.frame.width
                } else {
                    inset.right += clearButton.frame.width
                }
                textContainerInset = inset

                if let selectedTextRange = selectedTextRange, let font = font {
                    let caret = caretRect(for: selectedTextRange.start)
                    clearButtonCenterY = caret.midY + (caret.height - font.lineHeight)
                } else {
                    clearButtonCenterY = nil
                }
                self.clearButton = clearButton
            } else {
                clearButton = nil
            }
        }
    }

    override var delegate: UITextViewDelegate? {
        didSet {
            if delegate != nil, placeholder != nil {
                assert(delegate === self, "ThemeableTextView must be its own delegate to manage placeholder")
            }
        }
    }

    public func reset() {
        placeholder = nil
    }

    var placeholder: String? {
        didSet {
            isShowingPlaceholder = placeholder != nil
        }
    }

    public private(set) var isShowingPlaceholder: Bool = true {
        didSet {
            if isShowingPlaceholder {
                text = placeholder
                textColor = theme.colors.secondaryText
            } else {
                textColor = theme.colors.primaryText
            }
        }
    }

    override var text: String! {
        get {
            return isShowingPlaceholder ? "" : super.text
        }
        set {
            super.text = newValue
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        delegate = self
    }

    private var clearButtonCenterY: CGFloat?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let clearButton = clearButton else {
            return
        }
        let clearButtonOriginX: CGFloat
        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
            clearButtonOriginX = 0
        } else {
            clearButtonOriginX = frame.width - clearButton.frame.width
        }
        clearButton.frame = CGRect(x: clearButtonOriginX, y: textContainerInset.top, width: clearButton.frame.width, height: clearButton.frame.height)
        if let clearButtonCenterY = clearButtonCenterY {
            clearButton.center = CGPoint(x: clearButton.center.x, y: clearButtonCenterY)
        }
    }

    @objc private func clear() {
        text = nil
        setClearButtonHidden(true)
        clearDelegate?.themeableTextViewDidClear(self)
        UIAccessibility.post(notification: .layoutChanged, argument: self)
    }

    private func setClearButtonHidden(_ hidden: Bool) {
        guard
            let clearButton = clearButton,
            clearButton.isHidden != hidden
        else {
            return
        }
        clearButton.isHidden = hidden
    }
}

extension ThemeableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        _delegate?.textViewDidChange?(textView)
        setClearButtonHidden(textView.text.isEmpty)
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if firstTimeEditing {
            if textView.text.isEmpty, !isShowingPlaceholder {
                isShowingPlaceholder = true
                placeholderDelegate?.themeableTextViewPlaceholderDidHide(self, isPlaceholderHidden: false)
            } else if isShowingPlaceholder {
                textView.text = nil
                isShowingPlaceholder = false
                placeholderDelegate?.themeableTextViewPlaceholderDidHide(self, isPlaceholderHidden: true)
            }
        }
        firstTimeEditing = false
        return _delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        _delegate?.textViewDidEndEditing?(textView)
        setClearButtonHidden(true)
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return _delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        _delegate?.textViewDidBeginEditing?(textView)
        setClearButtonHidden(textView.text.isEmpty)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return _delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        _delegate?.textViewDidChangeSelection?(textView)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return _delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return _delegate?.textView?(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction) ?? true
    }
}

extension ThemeableTextView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        clearButton?.tintColor = theme.colors.tertiaryText
        backgroundColor = theme.colors.paperBackground
        textColor = isShowingPlaceholder ? theme.colors.secondaryText : theme.colors.primaryText
        keyboardAppearance = theme.keyboardAppearance
        if isUnderlined {
            layer.masksToBounds = false
            layer.shadowColor = theme.colors.tertiaryText.cgColor
            layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            layer.shadowOpacity = 1.0
            layer.shadowRadius = 0.0
        } else {
            layer.masksToBounds = true
            layer.shadowColor = nil
            layer.shadowOffset = CGSize.zero
            layer.shadowOpacity = 0.0
            layer.shadowRadius = 0.0
        }
    }
}

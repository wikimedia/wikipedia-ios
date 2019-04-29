protocol ThemeableTextViewPlaceholderDelegate: AnyObject {
    func themeableTextViewPlaceholderDidHide(_ themeableTextView: UITextView, isPlaceholderHidden: Bool)
}

class ThemeableTextView: UITextView {
    private var theme = Theme.standard
    public var isUnderlined = true
    private var firstTimeEditing = true

    weak var _delegate: UITextViewDelegate?
    weak var placeholderDelegate: ThemeableTextViewPlaceholderDelegate?

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
                textColor = theme.colors.tertiaryText
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
}

extension ThemeableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        _delegate?.textViewDidChange?(textView)
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
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return _delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        _delegate?.textViewDidBeginEditing?(textView)
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
        backgroundColor = theme.colors.paperBackground
        textColor = isShowingPlaceholder ? theme.colors.tertiaryText : theme.colors.primaryText
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

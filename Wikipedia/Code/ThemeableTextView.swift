class ThemeableTextView: UITextView {
    private var placeholderLabel = UILabel()
    private var theme = Theme.standard
    public var usesPlaceholder = true
    public var isUnderlined = true

    var _delegate: UITextViewDelegate? {
        didSet {
            if !usesPlaceholder {
                delegate = _delegate
            }
        }
    }

    override var delegate: UITextViewDelegate? {
        didSet {
            if usesPlaceholder {
                assert(delegate === self, "ThemeableTextView must be its own delegate to manage placeholder")
            }
        }
    }

    private func setup() {
        var inset = textContainerInset
        inset.left = -3
        textContainerInset = inset
        if usesPlaceholder {
            delegate = self
            placeholderLabel.numberOfLines = 0
            addSubview(placeholderLabel)
            placeholderLabel.frame.origin = placeholderLabelOrigin
            placeholderLabel.isHidden = !text.isEmpty
        }
    }

    private var placeholderLabelOrigin: CGPoint {
        let placeholderLabelX: CGFloat
        if let selectedTextRange = selectedTextRange {
            let caretPosition = caretRect(for: selectedTextRange.start)
            placeholderLabelX = caretPosition.maxX
        } else {
            placeholderLabelX = 0
        }
        return CGPoint(x: placeholderLabelX, y: 0)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    var placeholder: String? {
        didSet {
            if usesPlaceholder {
                placeholderLabel.text = placeholder
                placeholderLabel.frame.size = placeholderLabel.sizeThatFits(frame.size)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        placeholderLabel.font = font
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !placeholderLabel.isHidden else {
            return
        }
        let placeholderLabelHeight = placeholderLabel.sizeThatFits(CGSize(width: frame.width, height: UIView.noIntrinsicMetric)).height
        if frame.size.height != placeholderLabelHeight {
            frame.size.height = placeholderLabelHeight + textContainerInset.top + textContainerInset.bottom
        }
        let placeholderLabelSize = CGSize(width: frame.size.width, height: frame.size.height)
        if placeholderLabel.frame.size != placeholderLabelSize {
            placeholderLabel.frame.size = placeholderLabelSize
        }
    }

    override var intrinsicContentSize: CGSize {
        guard !placeholderLabel.isHidden else {
            return super.intrinsicContentSize
        }
        let placeholderLabelHeight = placeholderLabel.sizeThatFits(CGSize(width: frame.width, height: UIView.noIntrinsicMetric)).height
        let heightPlusInset = placeholderLabelHeight + textContainerInset.top + textContainerInset.bottom
        return CGSize(width: super.intrinsicContentSize.width, height: heightPlusInset)
    }
}

extension ThemeableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !text.isEmpty
        _delegate?.textViewDidChange?(textView)
    }
}

extension ThemeableTextView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.textColor = theme.colors.tertiaryText
        textColor = theme.colors.primaryText
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

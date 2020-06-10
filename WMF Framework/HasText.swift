
extension String {
    public var wmf_hasText: Bool {
        return !isEmpty
    }
    public var wmf_hasNonWhitespaceText: Bool {
        return wmf_hasText && !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    public var wmf_hasAlphanumericText: Bool {
        return wmf_hasText && (self.components(separatedBy: .alphanumerics).count > 1)
    }
}

extension NSAttributedString {
    public var wmf_hasText: Bool {
        return string.wmf_hasText
    }
    public var wmf_hasNonWhitespaceText: Bool {
        return string.wmf_hasNonWhitespaceText
    }
}

extension UILabel {
    public var wmf_hasText: Bool {
        guard let text = text else {
            return false
        }
        return text.wmf_hasText
    }

    @objc public var wmf_hasNonWhitespaceText: Bool {
        guard let text = text else {
            return false
        }
        return text.wmf_hasNonWhitespaceText
    }

    public var wmf_hasAttributedText: Bool {
        guard let attributedText = attributedText else {
            return false
        }
        return attributedText.wmf_hasText
    }

    public var wmf_hasNonWhitespaceAttributedText: Bool {
        guard let attributedText = attributedText else {
            return false
        }
        return attributedText.wmf_hasNonWhitespaceText
    }
    
    public var wmf_hasAnyText: Bool {
        return wmf_hasText || wmf_hasAttributedText
    }
    
    public var wmf_hasAnyNonWhitespaceText: Bool {
        return wmf_hasNonWhitespaceText || wmf_hasNonWhitespaceAttributedText
    }
}

extension UITextView {
    public var wmf_hasAnyNonWhitespaceText: Bool {
        return text?.wmf_hasNonWhitespaceText ?? false || attributedText?.wmf_hasNonWhitespaceText ?? false
    }
}

extension UIButton {
    public var wmf_hasText: Bool {
        guard let label = titleLabel else {
            return false
        }
        return label.wmf_hasText
    }
    
    public var wmf_hasNonWhitespaceText: Bool {
        guard let label = titleLabel else {
            return false
        }
        return label.wmf_hasNonWhitespaceText
    }
    
    public var wmf_hasAttributedText: Bool {
        guard let label = titleLabel else {
            return false
        }
        return label.wmf_hasText
    }
    
    public var wmf_hasNonWhitespaceAttributedText: Bool {
        guard let label = titleLabel else {
            return false
        }
        return label.wmf_hasNonWhitespaceText
    }
    
    public var wmf_hasAnyText: Bool {
        return wmf_hasText || wmf_hasAttributedText
    }
    
    public var wmf_hasAnyNonWhitespaceText: Bool {
        return wmf_hasNonWhitespaceText || wmf_hasNonWhitespaceAttributedText
    }
}

extension UITextField {
    public var wmf_hasText: Bool {
        guard let text = text else {
            return false
        }
        return text.wmf_hasText
    }
    
    public var wmf_hasNonWhitespaceText: Bool {
        guard let text = text else {
            return false
        }
        return text.wmf_hasNonWhitespaceText
    }
    
    public var wmf_hasAttributedText: Bool {
        guard let attributedText = attributedText else {
            return false
        }
        return attributedText.wmf_hasText
    }
    
    public var wmf_hasNonWhitespaceAttributedText: Bool {
        guard let attributedText = attributedText else {
            return false
        }
        return attributedText.wmf_hasNonWhitespaceText
    }
    
    public var wmf_hasAnyText: Bool {
        return wmf_hasText || wmf_hasAttributedText
    }
    
    public var wmf_hasAnyNonWhitespaceText: Bool {
        return wmf_hasNonWhitespaceText || wmf_hasNonWhitespaceAttributedText
    }
}

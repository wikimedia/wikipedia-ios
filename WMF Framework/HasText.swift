
extension String {
    public var wmf_hasText: Bool {
        return count > 0
    }
    public var wmf_hasNonWhitespaceText: Bool {
        return wmf_hasText && self.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
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
        guard let text = text, text.wmf_hasText else {
            return false
        }
        return true
    }

    public var wmf_hasNonWhitespaceText: Bool {
        guard let text = text, text.wmf_hasNonWhitespaceText else {
            return false
        }
        return true
    }

    public var wmf_hasAttributedText: Bool {
        guard let attributedText = attributedText, attributedText.wmf_hasText else {
            return false
        }
        return true
    }

    public var wmf_hasNonWhitespaceAttributedText: Bool {
        guard let attributedText = attributedText, attributedText.wmf_hasNonWhitespaceText else {
            return false
        }
        return true
    }
    
    public var wmf_hasAnyText: Bool {
        return wmf_hasText || wmf_hasAttributedText
    }
    
    public var wmf_hasAnyNonWhitespaceText: Bool {
        return wmf_hasNonWhitespaceText || wmf_hasNonWhitespaceAttributedText
    }
}

extension UIButton {
    public var wmf_hasText: Bool {
        guard let label = titleLabel, label.wmf_hasText else {
            return false
        }
        return true
    }
    
    public var wmf_hasNonWhitespaceText: Bool {
        guard let label = titleLabel, label.wmf_hasNonWhitespaceText else {
            return false
        }
        return true
    }
    
    public var wmf_hasAttributedText: Bool {
        guard let label = titleLabel, label.wmf_hasText else {
            return false
        }
        return true
    }
    
    public var wmf_hasNonWhitespaceAttributedText: Bool {
        guard let label = titleLabel, label.wmf_hasNonWhitespaceText else {
            return false
        }
        return true
    }
    
    public var wmf_hasAnyText: Bool {
        return wmf_hasText || wmf_hasAttributedText
    }
    
    public var wmf_hasAnyNonWhitespaceText: Bool {
        return wmf_hasNonWhitespaceText || wmf_hasNonWhitespaceAttributedText
    }
}

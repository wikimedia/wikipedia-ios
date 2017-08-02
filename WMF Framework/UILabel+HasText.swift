extension UILabel {
    public var wmf_hasText: Bool {
        return (text as NSString?)?.length ?? 0 > 0
    }

    public var wmf_hasAttributedText: Bool {
        return attributedText?.length ?? 0 > 0
    }
    
    public var wmf_hasAnyText: Bool {
        return wmf_hasText || wmf_hasAttributedText
    }
}

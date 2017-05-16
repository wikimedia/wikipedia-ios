extension UILabel {
    public var wmf_hasText: Bool {
        return (text as NSString?)?.length ?? 0 > 0
    }
}

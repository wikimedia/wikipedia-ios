class TagCollectionViewCell: CollectionViewCell {
    static let reuseIdentifier = "TagCollectionViewCell"
    fileprivate let label = UILabel()
    
    override func setup() {
        label.isOpaque = true
        contentView.addSubview(label)
        super.setup()
    }
    
    func configure(with tag: String) {
        label.text = tag
        label.backgroundColor = UIColor.yellow
        setNeedsLayout()
    }
    
    var semanticContentAttributeOverride: UISemanticContentAttribute = .unspecified {
        didSet {
            label.semanticContentAttribute = semanticContentAttributeOverride
        }
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        var origin = CGPoint.zero
        let widthToFit: CGFloat = 40
        
        if label.wmf_hasText {
            origin.y += label.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: 0, apply: apply)
        }
        
        return CGSize(width: size.width, height: origin.y)
    }
}

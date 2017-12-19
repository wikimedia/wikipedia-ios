struct Tag {
    let text: String
    let index: Int
}

class TagCollectionViewCell: CollectionViewCell {
    static let reuseIdentifier = "TagCollectionViewCell"
    fileprivate let label = UILabel()
    internal var width: CGFloat = 0
    
    override func setup() {
        label.isOpaque = true
        contentView.addSubview(label)
        super.setup()
    }
    
    func configure(with tag: Tag) {
        label.text = tag.text
        width = min(100, label.intrinsicContentSize.width)
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
        
        if label.wmf_hasText {
            origin.y += label.wmf_preferredHeight(at: origin, fitting: width, alignedBy: semanticContentAttributeOverride, spacing: 0, apply: apply)
        }
        
        return CGSize(width: size.width, height: origin.y)
    }
}

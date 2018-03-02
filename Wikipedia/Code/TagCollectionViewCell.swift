public struct Tag {
    let readingList: ReadingList
    let index: Int
    let indexPath: IndexPath
    
    var isLast: Bool {
        return index == 2
    }
}

class TagCollectionViewCell: CollectionViewCell {
    static let reuseIdentifier = "TagCollectionViewCell"
    private let label = UILabel()
    var width: CGFloat = 0
    let margins = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
    
    override func setup() {
        contentView.addSubview(label)
        layer.cornerRadius = 3
        clipsToBounds = true
        super.setup()
    }

    func configure(with tag: Tag, for count: Int, theme: Theme) {
        guard tag.index <= 2, let name = tag.readingList.name else {
            return
        }
        label.text = (tag.isLast ? "+\(count - 2)" : name).uppercased()
        label.translatesAutoresizingMaskIntoConstraints = false
        width = min(150, label.intrinsicContentSize.width)
        apply(theme: theme)
        updateFonts(with: traitCollection)
        setNeedsLayout()
    }
    
    var semanticContentAttributeOverride: UISemanticContentAttribute = .unspecified {
        didSet {
            label.semanticContentAttribute = semanticContentAttributeOverride
        }
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        label.setFont(with: .system, style: .footnote, traitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let availableWidth = width - margins.left - margins.right
        var x = margins.left
        if semanticContentAttributeOverride == .forceRightToLeft {
            x = width - x - availableWidth
        }
        print("label origin: \(label.frame.origin)")
        var origin = CGPoint(x: x, y: margins.top)
        if label.wmf_hasText {
            let tagLabel = label.wmf_preferredFrame(at: origin, fitting: availableWidth, alignedBy: semanticContentAttributeOverride, apply: true)
            origin.y += tagLabel.height
            
        }
        return CGSize(width: size.width, height: origin.y)
    }
    
    override func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        label.backgroundColor = labelBackgroundColor
    }
}

extension TagCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        label.textColor = theme.colors.secondaryText
        setBackgroundColors(theme.colors.midBackground, selected: theme.colors.baseBackground)
        updateSelectedOrHighlighted()
    }
}

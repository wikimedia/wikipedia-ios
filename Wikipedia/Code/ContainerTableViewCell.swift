import UIKit

class ContainerTableViewCell: SSBaseTableCell {

    var collectionViewCell: UICollectionViewCell!
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    // Any forced unwrapped variables above must be set before calling super.setup()
    open func setup() {

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        collectionViewCell.isSelected = selected
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        collectionViewCell.isHighlighted = highlighted
    }
    
    override var isHighlighted: Bool {
        get {
            return collectionViewCell.isHighlighted
        }
        set {
            collectionViewCell.isHighlighted = newValue
        }
    }
    
    override var isSelected: Bool {
        get {
            return collectionViewCell.isSelected
        }
        set {
            collectionViewCell.isSelected = newValue
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        collectionViewCell.prepareForReuse()
    }

    // MARK - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}

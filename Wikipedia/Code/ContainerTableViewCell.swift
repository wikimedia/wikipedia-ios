import UIKit

class ContainerTableViewCell: UITableViewCell {

    var collectionViewCell: UICollectionViewCell!
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    // Any forced unwrapped variables above must be set before calling super.setup()
    open func setup() {

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        collectionViewCell.isSelected = selected
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        collectionViewCell.isHighlighted = highlighted
    }
    
    override func prepareForReuse() {
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

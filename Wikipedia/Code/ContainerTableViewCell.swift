import UIKit

class ContainerTableViewCell: SSBaseTableCell {

    var collectionViewCell: UICollectionViewCell!
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    // Any forced unwrapped variables above must be set before calling super.setup()
    open func setup() {
        backgroundView = UIView()
        selectedBackgroundView = UIView()
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

extension ContainerTableViewCell: Themeable {
    func apply(theme: Theme) {
        if let themeableCell = collectionViewCell as? Themeable {
            themeableCell.apply(theme: theme)
        }
        backgroundView?.backgroundColor = collectionViewCell.backgroundView?.backgroundColor
        selectedBackgroundView?.backgroundColor = collectionViewCell.selectedBackgroundView?.backgroundColor
        
    }
}

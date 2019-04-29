
import UIKit

class ReplyListItemCollectionViewCell: CollectionViewCell {
    private let titleLabel = UILabel()
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        //todo: proper sizing
        return CGSize(width: size.width, height: 200)
    }
    
    func configure(title: String) {
        titleLabel.text = title
        titleLabel.sizeToFit()
    }
    
    override func setup() {
        contentView.addSubview(titleLabel)
        super.setup()
    }
}

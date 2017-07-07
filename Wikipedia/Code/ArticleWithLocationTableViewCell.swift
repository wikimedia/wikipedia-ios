import UIKit

class ArticleWithLocationTableViewCell: ContainerTableViewCell {
    var articleWithLocationCollectionViewCell: WMFNearbyArticleCollectionViewCell {
        return collectionViewCell as! WMFNearbyArticleCollectionViewCell
    }
    
    override func setup() {
        collectionViewCell = WMFNearbyArticleCollectionViewCell.wmf_classNib().instantiate(withOwner: nil, options: nil).first as! WMFNearbyArticleCollectionViewCell
        contentView.addSubview(collectionViewCell)
        collectionViewCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        collectionViewCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        collectionViewCell.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        collectionViewCell.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        super.setup()
    }
    
    class var estimatedRowHeight: CGFloat {
        return WMFNearbyArticleCollectionViewCell.estimatedRowHeight()
    }
}

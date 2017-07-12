import UIKit

class ArticleWithLocationTableViewCell: ContainerTableViewCell {
    var articleWithLocationCollectionViewCell: WMFNearbyArticleCollectionViewCell {
        return collectionViewCell as! WMFNearbyArticleCollectionViewCell
    }
    
    override func setup() {
        collectionViewCell = WMFNearbyArticleCollectionViewCell.wmf_classNib().instantiate(withOwner: nil, options: nil).first as! WMFNearbyArticleCollectionViewCell
        bounds = collectionViewCell.bounds
        addSubview(collectionViewCell)
        addConstraints([collectionViewCell.leadingAnchor.constraint(equalTo: leadingAnchor), collectionViewCell.trailingAnchor.constraint(equalTo: trailingAnchor), collectionViewCell.topAnchor.constraint(equalTo: topAnchor), collectionViewCell.bottomAnchor.constraint(equalTo: bottomAnchor)])
        super.setup()
    }
    
    class var estimatedRowHeight: CGFloat {
        return WMFNearbyArticleCollectionViewCell.estimatedRowHeight()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionViewCell.frame = bounds
    }
}

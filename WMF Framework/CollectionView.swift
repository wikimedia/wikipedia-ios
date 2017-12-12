import UIKit

@objc(WMFCollectionView)
class CollectionView: UICollectionView {
    override var contentInset: UIEdgeInsets {
        didSet {
            print("ci: \(contentInset)")
        }
    }

    override var contentOffset: CGPoint {
        didSet {
            print("co: \(contentOffset)")
        }
    }
}

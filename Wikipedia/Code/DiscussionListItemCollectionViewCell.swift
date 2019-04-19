
import UIKit

class DiscussionListItemCollectionViewCell: CollectionViewCell {

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        return CGSize(width: size.width, height: 10)
    }
}

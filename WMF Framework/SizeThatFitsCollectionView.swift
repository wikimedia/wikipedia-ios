import UIKit

public class SizeThatFitsCollectionView: UICollectionView {
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: contentSize.height)
    }
}

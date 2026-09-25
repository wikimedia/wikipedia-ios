extension UITableViewController {
}

extension UICollectionViewController {
    fileprivate func scrollToTop() {
        guard let collectionView = self.collectionView else {
            return
        }
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: 0 - collectionView.contentInset.top), animated: true)
    }
}

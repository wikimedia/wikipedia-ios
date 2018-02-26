extension UITableViewController {
    fileprivate func scrollToFirstIndexPath() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0) , at: .top, animated: true)
    }
}

extension UICollectionViewController {
    fileprivate func scrollToTop() {
        guard let collectionView = self.collectionView else {
            return
        }
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: 0 - collectionView.contentInset.top), animated: true)
    }
}

extension ArticleCollectionViewController {
    @objc func scrollToTop(_ isScrollable: Bool) {
        guard isScrollable else { return }
        scrollToTop()
    }
}

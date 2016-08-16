
extension UITableViewController {
    fileprivate func scrollToFirstIndexPath() {
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0) , atScrollPosition: .Top, animated: true)
    }
}

extension UICollectionViewController {
    fileprivate func scrollToFirstIndexPath() {
        collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0) , atScrollPosition: .Top, animated: true)
    }
}

extension WMFArticleListTableViewController {
    func scrollToTop(_ isScrollable: Bool) {
        guard isScrollable else { return }
        scrollToFirstIndexPath()
    }
}

extension WMFExploreViewController {
    func scrollToTop() {
        guard canScrollToTop else { return }
        scrollToFirstIndexPath()
    }
}

//
//  UITableViewController+WMFScrollToTop.swift
//  Wikipedia
//
//  Created by Kevin Taniguchi on 7/17/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

extension UITableViewController {
    private func scrollToFirstIndexPath() {
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0) , atScrollPosition: .Top, animated: true)
    }
}

extension WMFArticleListTableViewController {
    func scrollToTop(isScrollable: Bool) {
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

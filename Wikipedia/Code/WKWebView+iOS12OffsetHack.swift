extension WKWebView {
    @objc var iOS12yOffsetHack: CGFloat {
        if #available(iOS 12, *) {
            let topContentInset = scrollView.contentInset.top
            let yContentOffset = scrollView.contentOffset.y
            if (topContentInset + yContentOffset != 0) {
                return 0 - topContentInset - min(0, yContentOffset)
            }
        }
        return 0
    }
}

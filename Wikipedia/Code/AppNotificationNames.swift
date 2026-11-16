import Foundation

extension Notification.Name {
    static let showErrorBanner = Notification.Name("WMFShowErrorBanner")
    static let showErrorBannerNSErrorKey = "nserror"
    static let articleViewControllerDidDisappear = Notification.Name("WMFArticleViewControllerDidDisappear")
    static let dismissReadingListToast = Notification.Name("WMFDismissReadingListToast")
}

@objc extension NSNotification {
    public static let showErrorBanner = Notification.Name.showErrorBanner
    static let showErrorBannerNSErrorKey = Notification.Name.showErrorBannerNSErrorKey
    public static let articleViewControllerDidDisappear = Notification.Name.articleViewControllerDidDisappear
    public static let dismissReadingListToast = Notification.Name.dismissReadingListToast
}

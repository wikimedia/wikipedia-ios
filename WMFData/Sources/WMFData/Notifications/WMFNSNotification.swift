import Foundation

/// Namespace for all NSNotification events used by WMFData
public enum WMFNSNotification {
    
    public static let articleTabDeleted = Notification.Name(WMFNotificationName.articleTabDeleted.rawValue)
    public static let articleTabItemDeleted = Notification.Name(WMFNotificationName.articleTabItemDeleted.rawValue)
    public static let coreDataStoreSetup = Notification.Name(WMFNotificationName.coreDataStoreSetup.rawValue)
    
    /// User info keys for notifications
    public enum UserInfoKey {
        public static let articleTabIdentifier = "articleTabIdentifier"
        public static let articleTabItemIdentifier = "articleTabIdentifier"
    }
}

/// Private enum to ensure unique notification names
private enum WMFNotificationName: String {
    case articleTabDeleted = "WMFDataArticleTabDeleted"
    case articleTabItemDeleted = "WMFDataArticleTabItemDeleted"
    case coreDataStoreSetup = "WMFDataCoreDataStoreSetup"
}

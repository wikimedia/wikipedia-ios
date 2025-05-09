import Foundation

/// Namespace for all NSNotification events used by WMFData
public enum WMFNSNotification {
    
    public static let articleTabDeleted = Notification.Name(WMFNotificationName.articleTabDeleted.rawValue)
    public static let coreDataStoreSetup = Notification.Name(WMFNotificationName.coreDataStoreSetup.rawValue)
    
    /// User info keys for notifications
    public enum UserInfoKey {
        public static let articleTabIdentifier = "articleTabIdentifier"
    }
}

/// Private enum to ensure unique notification names
private enum WMFNotificationName: String {
    case articleTabDeleted = "WMFDataArticleTabDeleted"
    case coreDataStoreSetup = "WMFDataCoreDataStoreSetup"
}

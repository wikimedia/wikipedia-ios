import Foundation

/// Namespace for all NSNotification events used by WMFData
public enum WMFNSNotification {
    
    public static let articleTabDeleted = Notification.Name(WMFNotificationName.articleTabDeleted.rawValue)
    public static let articleTabItemDeleted = Notification.Name(WMFNotificationName.articleTabItemDeleted.rawValue)
    public static let coreDataStoreSetup = Notification.Name(WMFNotificationName.coreDataStoreSetup.rawValue)
    public static let sharedCacheStoreSetup = Notification.Name(WMFNotificationName.sharedCacheStoreSetup.rawValue)
    public static let refreshExploreForGamesCard = Notification.Name(WMFNotificationName.refreshExploreForGamesCard.rawValue)
    public static let whichCameFirstSessionDidUpdate = Notification.Name(WMFNotificationName.whichCameFirstSessionDidUpdate.rawValue)
    public static let gamesAllSessionsCleared = Notification.Name(WMFNotificationName.gamesAllSessionsCleared.rawValue)
    public static let enableHomeTabDidChange = Notification.Name(WMFNotificationName.enableHomeTabDidChange.rawValue)
    public static let enableHomePhase2DidChange = Notification.Name(WMFNotificationName.enableHomePhase2DidChange.rawValue)
    public static let communityModuleVisibilityDidChange = Notification.Name(WMFNotificationName.communityModuleVisibilityDidChange.rawValue)
    public static let forYouModuleVisibilityDidChange = Notification.Name(WMFNotificationName.forYouModuleVisibilityDidChange.rawValue)
    public static let forYouInterestsDidChange = Notification.Name(WMFNotificationName.forYouInterestsDidChange.rawValue)

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
    case sharedCacheStoreSetup = "WMFDataSharedCacheStoreSetup"
    case refreshExploreForGamesCard = "WMFDataRefreshExploreForGamesCard"
    case whichCameFirstSessionDidUpdate = "WMFDataWhichCameFirstSessionDidUpdate"
    case gamesAllSessionsCleared = "WMFDataGamesAllSessionsCleared"
    case enableHomeTabDidChange = "WMFDataEnableHomeTabDidChange"
    case enableHomePhase2DidChange = "WMFDataEnableHomePhase2DidChange"
    case communityModuleVisibilityDidChange = "WMFDataCommunityModuleVisibilityDidChange"
    case forYouModuleVisibilityDidChange = "WMFDataForYouModuleVisibilityDidChange"
    case forYouInterestsDidChange = "WMFDataForYouInterestsDidChange"
}

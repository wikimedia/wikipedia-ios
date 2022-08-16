import Foundation
import WMF

/// Persisted object to contain additional useful data for User Data Export.
public struct UserDataExportSyncInfo: Codable {
    public let serverReadingLists: [APIReadingList]
    public let serverReadingListEntries: [APIReadingListEntry]
    public let appSettingsSyncSavedArticlesAndLists: Bool
    public let appSettingsShowSavedReadingList: Bool
    
    public init(serverReadingLists: [APIReadingList], serverReadingListEntries: [APIReadingListEntry], appSettingsSyncSavedArticlesAndLists: Bool, appSettingsShowSavedReadingList: Bool) {
        self.serverReadingLists = serverReadingLists
        self.serverReadingListEntries = serverReadingListEntries
        self.appSettingsSyncSavedArticlesAndLists = appSettingsSyncSavedArticlesAndLists
        self.appSettingsShowSavedReadingList = appSettingsShowSavedReadingList
    }
}

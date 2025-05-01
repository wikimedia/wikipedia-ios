import Foundation
import UIKit
import CoreData

public class WMFArticleTabsDataController {
    
    public let coreDataStore: WMFCoreDataStore
    private let userDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {

        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
        self.userDefaultsStore = userDefaultsStore
        self.developerSettingsDataController = developerSettingsDataController
    }
    
    // MARK: Entry point

   public var shouldShowArticleTabs: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsArticleTab.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsArticleTab.rawValue, value: newValue)
        }
    }
}

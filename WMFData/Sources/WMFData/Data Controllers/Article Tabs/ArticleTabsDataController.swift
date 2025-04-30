//
//  ArticleTabsDataController.swift
//  WMFData
//
//  Created by Grey Olson on 4/30/25.
//

import Foundation
import UIKit
import CoreData

@objc public class ArticleTabsDataController: NSObject {
    
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

    @objc public var shouldShowArticleTabs: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsArticleTab.rawValue)) ?? true
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsArticleTab.rawValue, value: newValue)
        }
    }
}

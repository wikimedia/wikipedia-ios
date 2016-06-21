//
//  WMFLegacyImageDataMigration.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import CocoaLumberjackSwift


enum LegacyImageDataMigrationError : CancellableErrorType {
    case Deinit

    var cancelled: Bool {
        return true
    }
}

/// Migrate legacy image data for saved pages into WMFImageController.
@objc
public class WMFLegacyImageDataMigration : NSObject {
    /// Image controller where data will be migrated.
    let imageController: WMFImageController

    /// Data store which provides articles and saves the entries after processing.
    let legacyDataStore: MWKDataStore

    /// Background task manager which invokes the receiver's methods to migrate image data in the background.
    private lazy var backgroundTaskManager: WMFBackgroundTaskManager<MWKSavedPageEntry> = {
        WMFBackgroundTaskManager(
        next: { [weak self] in
            return self?.unmigratedEntry()
        },
        processor: { [weak self] entry in
            return self?.migrateEntry(entry) ?? Promise<Void>(error: LegacyImageDataMigrationError.Deinit)
        },
        finalize: { [weak self] in
            return self?.save() ?? Promise()
        })
    }()

    /// Initialize a new migrator.
    public required init(imageController: WMFImageController = WMFImageController.sharedInstance(),
                         legacyDataStore: MWKDataStore) {
        self.imageController = imageController
        self.legacyDataStore = legacyDataStore
        super.init()
    }

    public func setupAndStart() -> Promise<Void> {
        return self.backgroundTaskManager.start()
    }

    public func setupAndStart() -> AnyPromise {
        return AnyPromise(bound: setupAndStart())
    }

    /// MARK: - Testable Methods

    func save() -> Promise<Void> {
        return firstly {
            return legacyDataStore.userDataStore.savedPageList.save()
        }.asVoid()
    }

    func unmigratedEntry() -> MWKSavedPageEntry? {
        var entry: MWKSavedPageEntry?
        let getUnmigratedEntry = {
            let allEntries = self.legacyDataStore.userDataStore.savedPageList.entries as! [MWKSavedPageEntry]
            entry = allEntries.filter() { $0.didMigrateImageData == false }.first
        }
        if NSThread.isMainThread() {
            getUnmigratedEntry()
        } else {
            dispatch_sync(dispatch_get_main_queue(), getUnmigratedEntry)
        }
        return entry
    }

    /// Migrate all images in `entry` into `imageController`, then mark it as migrated.
    func migrateEntry(entry: MWKSavedPageEntry) -> Promise<Void> {
        DDLogDebug("Migrating entry \(entry)")
        return migrateAllImagesInArticleWithTitle(entry.title)
        .then() { [weak self] in
            self?.markEntryAsMigrated(entry)
        }
    }

    /// Move an article's images into `imageController`, ignoring any errors.
    func migrateAllImagesInArticleWithTitle(title: MWKTitle) -> Promise<Void> {
        if let images = legacyDataStore.existingArticleWithTitle(title)?.allImageURLs() {
            if images.count > 0 {
                return images.reduce(Promise()) { (chain, url) -> Promise<Void> in
                    return chain.then(on: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { [weak self] in
                        guard let `self` = self else {
                            return Promise(error: LegacyImageDataMigrationError.Deinit)
                        }
                        let filepath = self.legacyDataStore.pathForImageData(url.absoluteString, title: title)
                        
                        return Promise<Void> { fulfill, reject in
                            let failure = { (error: ErrorType) -> Void in
                                #if DEBUG
                                    reject(error)
                                #else
                                    fulfill()
                                #endif
                                
                            }
                            let success = { () -> Void in
                                fulfill()
                            }
                            self.imageController.importImage(fromFile: filepath, withURL: url, failure: failure, success: success)
                        }
                    }
                }.asVoid()
            }
        }
        return Promise()
    }

    /// Mark the given entry as having its image data migrated.
    func markEntryAsMigrated(entry: MWKSavedPageEntry) {
        legacyDataStore.userDataStore.savedPageList.markImageDataAsMigratedForEntryWithTitle(entry.title)
    }
}
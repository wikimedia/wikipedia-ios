//
//  WMFLegacyImageDataMigration.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import PromiseKit

/// Migrate legacy image data for saved pages into WMFImageController.
@objc
public class WMFLegacyImageDataMigration : NSObject {
    //XC6: @testable
    /// Image controller where data will be migrated.
    public let imageController: WMFImageController

    //XC6: @testable
    /// List of saved pages which is saved when the tasks are finished processing.
    public lazy var savedPageList: MWKSavedPageList = {
        self.legacyDataStore.userDataStore().savedPageList
    }()

    /// Data store which provides articles and saves the entries after processing.
    private let legacyDataStore: MWKDataStore

    static let savedPageQueueLabel = "org.wikimedia.wikipedia.legacyimagemigration.savedpagelist"

    /// Serial queue for manipulating `savedPageList`.
    private lazy var savedPageQueue: dispatch_queue_t = {
        let savedPageQueue = dispatch_queue_create(savedPageQueueLabel, DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(savedPageQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
        return savedPageQueue
    }()

    /// Background task manager which invokes the receiver's methods to migrate image data in the background.
    private lazy var backgroundTaskManager: WMFBackgroundTaskManager<MWKSavedPageEntry> = {
        WMFBackgroundTaskManager(
        next: { [weak self] in
            return self?.unmigratedEntry()
        },
        processor: { [weak self] entry in
            return self?.migrateEntry(entry) ?? Promise<Void>(NSError.cancelledError())
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

    //XC6: @testable
    /// Save the receiver's saved page list, making sure to preserve the current list on disk.
    public func save() -> Promise<Void> {
        // for each entry that we migrated
        let migratedEntries = savedPageList.entries.filter() { $0.didMigrateImageData == true } as! [MWKSavedPageEntry]
        let currentSavedPageList = legacyDataStore.userDataStore().savedPageList
        // grab the corresponding entry from the list on disk
        for migratedEntry: MWKSavedPageEntry in migratedEntries {
            currentSavedPageList.updateEntryWithTitle(migratedEntry.title) { entry in
                if !entry.didMigrateImageData {
                    // mark as migrated if necessary, and mark the list as dirty
                    entry.didMigrateImageData = true
                    return true
                } else {
                    // if already migrated, leave dirty flag alone
                    return false
                }
            }
        }
        // save if dirty
        return Promise().then() { () -> AnyPromise in
            return currentSavedPageList.save()
        }.asVoid()
    }

    //XC6: @testable
    public func unmigratedEntry() -> MWKSavedPageEntry? {
        var entry: MWKSavedPageEntry?
        dispatch_sync(savedPageQueue) {
            let allEntries = self.savedPageList.entries as! [MWKSavedPageEntry]
            entry = allEntries.filter() { $0.didMigrateImageData == false }.first
        }
        return entry
    }

    //XC6: @testable
    /// Migrate all images in `entry` into `imageController`, then mark it as migrated.
    public func migrateEntry(entry: MWKSavedPageEntry) -> Promise<Void> {
        NSLog("Migrating entry \(entry)")
        return migrateAllImagesInArticleWithTitle(entry.title)
        .then(on: savedPageQueue) { [weak self] in
            self?.markEntryAsMigrated(entry)
        }
    }

    //XC6: @testable
    /// Move an article's images into `imageController`, ignoring any errors.
    public func migrateAllImagesInArticleWithTitle(title: MWKTitle) -> Promise<Void> {
        if let images = legacyDataStore.existingArticleWithTitle(title)?.allImageURLs() as? [NSURL] {
            if images.count > 0 {
                return images.reduce(Promise()) { (chain, url) -> Promise<Void> in
                    return chain.then(on: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { [weak self] in
                        if let sself = self {
                            let filepath = sself.legacyDataStore.pathForImageData(url.absoluteString, title: title)
                            let promise = sself.imageController.importImage(fromFile: filepath, withURL: url)
                            return promise.recover() { (error: ErrorType) -> Promise<Void> in
                                #if DEBUG
                                // only return errors in debug, silently fail in production
                                if (error as NSError).code != NSFileNoSuchFileError {
                                    return Promise(error: error)
                                }
                                #endif
                                return Promise()
                            }
                        } else {
                            return Promise()
                        }
                    }
                }.asVoid()
            }
        }
        return Promise()
    }

    //XC6: @testable
    /// Mark the given entry as having its image data migrated.
    public func markEntryAsMigrated(entry: MWKSavedPageEntry) {
        savedPageList.updateEntryWithTitle(entry.title) { e in
            e.didMigrateImageData = true
            return true
        }
    }
}
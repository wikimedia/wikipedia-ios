//
//  WMFLegacyImageDataMigrationTests.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/7/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

@testable import Wikipedia
import PromiseKit

@objc
class WMFLegacyImageDataMigrationTests : XCTestCase {
    var dataStore: MWKDataStore!

    var savedPageList: MWKSavedPageList {
        return self.dataStore.userDataStore.savedPageList
    }

    // Array of paths to temporary files that need to be cleaned up in tearDown
    var tmpImageDirectory: String!

    var imageMigration: WMFLegacyImageDataMigration!

    override func setUp() {
        dataStore = MWKDataStore.temporaryDataStore()

        imageMigration = WMFLegacyImageDataMigration(imageController: WMFImageController.temporaryController(),
                                                     legacyDataStore: self.dataStore)

        tmpImageDirectory = WMFRandomTemporaryPath()
        try! NSFileManager.defaultManager().createDirectoryAtPath(tmpImageDirectory,
                                                                  withIntermediateDirectories: true,
                                                                  attributes: nil)
        super.setUp()
    }

    override func tearDown() {
        imageMigration.imageController.deleteAllImages()
        dataStore.removeFolderAtBasePath()
        dataStore = nil
        try! NSFileManager.defaultManager().removeItemAtPath(tmpImageDirectory)
        super.tearDown()
    }

    func testUnmigratedEntriesIsNilWhenSavedPageListIsEmpty() {
        XCTAssertNil(imageMigration.unmigratedEntry())
    }

    func testUnmigratedEntriesCorrectlyReturnsUnmigratedEntry() {
        addEntryWithTitleText("migrated", didMigrate: true)
        addEntryWithTitleText("migrated2", didMigrate: true)
        let unmigratedEntry = addEntryWithTitleText("unmigrated", didMigrate: false)

        expectPromise(toResolve()) {
            Promise().then() { _ -> AnyPromise in
                return self.savedPageList.save()
            }
            .then() { _ -> Void in
                XCTAssertNotNil(self.imageMigration.unmigratedEntry())
                XCTAssertEqual(
                    self.savedPageList.entryForListIndex(unmigratedEntry.title)!,
                    self.imageMigration.unmigratedEntry()!)
                XCTAssertEqual(
                    self.imageMigration.unmigratedEntry()!,
                    self.imageMigration.unmigratedEntry()!,
                    "The entry returned by unmigratedEntry() should not change until new data has been saved")
            }
        }
    }

    func testMarkingAnEntryAsMigratedCausesUnmigratedEntryToReturnNextEntryOrNil() {
        addEntryWithTitleText("foo", didMigrate: true)
        addEntryWithTitleText("bar", didMigrate: false)
        addEntryWithTitleText("baz", didMigrate: false)
        expectPromise(toResolve(),
        pipe: {
            let result = self.imageMigration.unmigratedEntry()
            XCTAssertNil(
                result,
                "Expected nil result after marking all entries as migrated, but got \(result). Current entries:\n"
                    + self.dataStore.userDataStore.savedPageList.entries.debugDescription)
            let unmigratedEntries = (self.dataStore.userDataStore.savedPageList.entries as! [MWKSavedPageEntry]).filter() { $0.didMigrateImageData == false }
            XCTAssertTrue(unmigratedEntries.isEmpty, "Expected data store to contain 0 unmigrated entries")
        },
        test: {
            firstly() { self.savedPageList.save() }.then() { _ -> Promise<Void> in
                // not asserting which entry is returned, since order is arbitrary
                self.imageMigration.markEntryAsMigrated(self.imageMigration.unmigratedEntry()!)
                self.imageMigration.markEntryAsMigrated(self.imageMigration.unmigratedEntry()!)
                return self.imageMigration.save()
            }
        })
    }

    func testMigrateAllImagesResovlesWhenArticleDoesNotExist() {
        let nonExistentTitle = MWKSite.siteWithCurrentLocale().titleWithString("foo")
        expectPromise(toResolve()) {
            self.imageMigration.migrateAllImagesInArticleWithTitle(nonExistentTitle)
        }
    }

    func testMigrateAllImagesResolvesWhenArticleHasNoImages() {
        let title = MWKSite.siteWithCurrentLocale().titleWithString("foo")
        let article = MWKArticle(title: title, dataStore: dataStore)
        article.importMobileViewJSON(wmf_bundle().wmf_jsonFromContentsOfFile("ArticleWithoutImages.dataexport") as! [NSObject : AnyObject])
        assert(article.allImageURLs().isEmpty, "Article for this test must have 0 images")
        article.save()
        expectPromise(toResolve()) {
            self.imageMigration.migrateAllImagesInArticleWithTitle(title)
        }
    }

    func testSetupAndStartMigrationWithObamaMigratesSuccessfully() {
        let (article, legacyImageDataPaths) = prepareArticleFixtureWithTempImages("Barack_Obama")

        // mark Barack_Obama as an unmigrated entry
        addUnmigratedEntryForListIndex(article.title)

        expectPromise(toResolve(),
        timeout: 10,
        pipe: {
            XCTAssertNil(self.imageMigration.unmigratedEntry(), "Should be no remaining unmigrated entries")
            let migratedEntry = self.dataStore.userDataStore.savedPageList.entryForListIndex(article.title)!
            XCTAssertTrue(migratedEntry.didMigrateImageData, "Expected article's saved page entry to be marked as migrated")
            self.verifySuccessfulMigration(ofArticle: article, legacyImageDataPaths: legacyImageDataPaths)
        },
        test: { () -> Promise<Void> in
            Promise().then() { _ -> AnyPromise in
                return self.savedPageList.save()
            }
            .then() { _ -> Promise<Void> in
                self.imageMigration.setupAndStart()
            }
            .asVoid()
        })
    }

    func testMigratingMultipleArticlesAfterSavedPageListIsMutatedDoesNotAlterTheMutatedList() {
        let title1 = MWKTitle(string: "Barack_Obama", site: MWKSite.siteWithCurrentLocale())
        let (article2, legacyImageDataPaths2) = prepareArticleFixtureWithTempImages("Barack_Obama", titleText: "Dupe1")
        let titleToAddWhileMigrating = MWKTitle(string: "addedWhileMigrating", site: MWKSite.siteWithCurrentLocale())

        // create saved page entries for 1 & 2, which will be migrated
        addUnmigratedEntryForListIndex(title1)
        addUnmigratedEntryForListIndex(article2.title)

        expectPromise(toResolve(),
        timeout: 10,
        pipe: {
            XCTAssertNil(self.imageMigration.unmigratedEntry(), "Should be no remaining unmigrated entries")

            let currentSavedPageList = self.savedPageList

            XCTAssertNil(currentSavedPageList.entryForListIndex(title1),
                         "Entry for article1 should have remained deleted.")

            XCTAssertTrue(currentSavedPageList.entryForListIndex(article2.title)!.didMigrateImageData,
                          "Expected article2 to still be in the list and marked as migrated (by imageMigration).")

            XCTAssertTrue(currentSavedPageList.entryForListIndex(titleToAddWhileMigrating)!.didMigrateImageData,
                          "Expected article3 to still be in the list and marked as migrated (by default).")

            // article 1 should still have been migrated, including deletion of legacy image data
            self.verifySuccessfulMigration(ofArticle: article2, legacyImageDataPaths: legacyImageDataPaths2)
        },
        test: { () -> Promise<Void> in
            Promise().then() { _ -> AnyPromise in
                return self.savedPageList.save()
            }
            .then() { _ -> AnyPromise in
                // remove article 1
                self.savedPageList.removeEntryWithListIndex(title1)

                // save article 3
                self.savedPageList.addSavedPageWithTitle(titleToAddWhileMigrating)

                return self.savedPageList.save()
            }
            .then() { _ -> Promise<Void> in
                self.imageMigration.setupAndStart()
            }
            .asVoid()
        })
    }

    // MARK: - Test Utilities

    func prepareArticleFixtureWithTempImages(fixtureName: String, titleText: String? = nil) -> (MWKArticle, [NSURL:String]) {
        let title = MWKSite.siteWithCurrentLocale().titleWithString(titleText ?? fixtureName)
        let article = self.completeArticleWithLegacyDataInFolder(fixtureName,
                                                                 withTitle: title,
                                                                 insertIntoDataStore: dataStore)

        // copy all legacy data to a tmp folder for later comparison
        let legacyImageDataPaths = article.allImageURLs().reduce(Dictionary<NSURL,String>()) { memo, url in
            let legacyImageData = dataStore.imageDataWithImage(MWKImage(article: article,
                sourceURLString: url.absoluteString))
            assert(legacyImageData.length != 0, "Images in the test article must have data for this test")
            let tmpPathForURL = NSURL(fileURLWithPath: tmpImageDirectory, isDirectory: true)
                                .URLByAppendingPathComponent(url.lastPathComponent!)
            assert(legacyImageData.writeToURL(tmpPathForURL, atomically: false),
                   "failed to write image data to tmp file \(tmpPathForURL)")
            var appendedMemo = memo
            appendedMemo[url] = tmpPathForURL.path
            return appendedMemo
        }
        return (article, legacyImageDataPaths)
    }

    func addUnmigratedEntryForListIndex(title: MWKTitle) {
        savedPageList.addSavedPageWithTitle(title)
        savedPageList.markImageDataAsMigrated(false, forEntryWithTitle: title)
    }

    func verifySuccessfulMigration(articles: [MWKArticle], legacyImageDataPaths: [NSURL:String]) {
        for article in articles {
            verifySuccessfulMigration(ofArticle: article, legacyImageDataPaths: legacyImageDataPaths)
        }
    }

    func verifySuccessfulMigration(ofArticle article: MWKArticle, legacyImageDataPaths: [NSURL:String]) {
        for url in article.allImageURLs() {
            XCTAssertTrue(self.imageMigration.imageController.hasDataOnDiskForImageWithURL(url),
                "imageMigration didn't import image with url: \(url)")

            XCTAssertFalse(self.imageMigration.imageController.hasDataInMemoryForImageWithURL(url),
                "image migration should not store migrated images in memory to prevent bloating")

            // use XCTAssertTrue instead of XCTAssertNil to prevent noisy logging of image data on failure
            let imageFromDataStore = self.dataStore.imageDataWithImage(MWKImage(article: article, sourceURLString: url.absoluteString))
            XCTAssertTrue(imageFromDataStore == nil,
                          "Legacy image data for title \(article.title) not deleted for image with url: \(url)")

            let legacyData: NSData? = NSFileManager.defaultManager().contentsAtPath(legacyImageDataPaths[url]!)
            let migratedData: NSData? = self.imageMigration.imageController.diskDataForImageWithURL(url)
            XCTAssertNotNil(migratedData, "Migrated data missing for \(url)")
            XCTAssertTrue(legacyData == migratedData, "Migrated data and legacy data not identical for \(url)")
        }
    }

    func addEntryWithTitleText(text: String, didMigrate migrated: Bool) -> MWKSavedPageEntry {
        let title = MWKTitle(site: MWKSite.siteWithCurrentLocale(), normalizedTitle: text, fragment: nil)
        let entry = MWKSavedPageEntry(title: title)
        savedPageList.addEntry(entry)
        savedPageList.markImageDataAsMigrated(migrated, forEntryWithTitle: title)
        return entry
    }
}

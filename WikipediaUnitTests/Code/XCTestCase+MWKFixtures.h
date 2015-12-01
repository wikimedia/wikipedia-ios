//
//  XCTestCase+MWKFixtures.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MediaWikiKit.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKArticle;
@class MWKTitle;
@class MWKDataStore;


@interface XCTestCase (MWKFixtures)

/**
 * Create an article from fixture data, give it the specified title, and insert it into the given data store.
 *
 * The fixture data should be JSON, which can either be the raw response from mobileview or the JSON returned by
 * `-[MWKArticle dataExport]`. Keep in mind that other properties of the article might not be populated. To ensure
 * an article fixture is "complete" (i.e. images, sections, etc.), use `completeArticleWithLegacyDataInFolder`.
 *
 * @param fixtureName   The name of the JSON file you want to use (e.g. "Obama" for "Obama.json"), see description for
 *                      explanation of which fixtures are appropriate.
 * @param titleOrString Either an `MWKTitle` or `NSString` to derive the title from (using current site).
 * @param dataStore     Data store to insert the article into.
 *
 * @return An article object populated with data from the specified fixture.
 *
 * @see completeArticleWithLegacyDataInFolder:withData:insertIntoDataStore
 */
- (MWKArticle*)articleWithMobileViewJSONFixture:(NSString*)fixtureName
                                      withTitle:(id)titleOrString
                                      dataStore:(MWKDataStore*)dataStore;

/**
 * Similar to `articleWithMobileViewJSONFixture`, but using an entire folder of data instead of a single mobileview
 * json fixture.
 *
 * This allows a tester to create articles as they would be after being fetched by the article fetcher by copying
 * the legacy data folder into the "Fixtures" folder.
 *
 * 1. View page in the app
 * 2. Go to the folder for the title you just viewed: "<App Container>/Documents/Data/sites/<site>/<title>"
 * 3. Drag that folder into the "WikipediaUnitTests/Fixtures" group
 * 3a. NOTE: Select "Copy items if needed"
 * 3b. NOTE: Select "Create folder reference" (this makes sure that the test bundle copies the contents of the folder
 *     recursively while preserving directory structure.
 * 5. Call this method to get an article populated with data from that folder:
 *
 *     MWKArticle* testArticle = [self completeArticleWithLegacyDataInFolder:@"Barack_Obama" withTitle:@"foo" insertIntoDataStore:self.dataStore];
 *
 * @param folderName    The name of the folder you want to import (see description).
 * @param titleOrString Either an `MWKTitle` or `NSString` to derive the title from (using current site).
 * @param dataStore     Data store to insert the article into.
 *
 * @return An article object populated with data from the specified fixture.
 *
 * @see -articleWithMobileViewJSONFixture:withTitle:insertIntoDataStore:
 * @see -[MWKDataStore(TemporaryDataStore) articleWithImportedDataFromFolderAtPath:title:]
 */
- (MWKArticle*)completeArticleWithLegacyDataInFolder:(NSString*)folderName
                                           withTitle:(id)titleOrString
                                 insertIntoDataStore:(MWKDataStore*)dataStore;

@end


@interface MWKDataStore (Fixtures)

/**
 * Populate the receiver with complete article data (including legacy images) from the given folder.
 *
 * @param path  Path to a folder containing legacy article data.
 *
 * @param title The title under which the data will be stored.  This allows the tester to import fixture data from the
 *              "Barack_Obama" folder (or any other) under any arbitrary title.
 *
 * @return An artricle which is deserialized by the receiver after importing the data.
 *
 * @see -[XCTestCase(MWKFixtures completeArticleWithLegacyDataInFolder:withTitle:insertIntoDataStore:]
 */
- (MWKArticle*)articleWithImportedDataFromFolderAtPath:(NSString*)path title:(MWKTitle*)title;

@end

NS_ASSUME_NONNULL_END
//
//  MWKSavedPageListLegacyTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+DataStoreFixtureTesting.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageListDataExportConstants.h"
#import "Wikipedia-Swift.h"
#import "XCTestCase+PromiseKit.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKListLegacyTests : XCTestCase
@property (nonatomic, strong) MWKDataStore* dataStore;
@end

@implementation MWKListLegacyTests

- (void)setUp {
    [super setUp];
    self.dataStore = [self wmf_temporaryCopyOfDataStoreFixtureAtPath:@"4.1.7/Valid"];
}

- (void)tearDown {
    [self.dataStore removeFolderAtBasePath];
    [super tearDown];
}

#pragma mark - Saved Pages

- (void)testReordersLegacySavedPageList {
    NSArray<MWKSavedPageEntry*>* legacyEntries =
        [[self.dataStore savedPageListData][MWKSavedPageExportedEntriesKey] bk_map:^id (NSDictionary* entryData) {
        MWKSavedPageEntry* entry;
        XCTAssertNoThrow((entry = [[MWKSavedPageEntry alloc] initWithDict:entryData]),
                         @"not expecting invalid entries for this test");
        return entry;
    }];
    NSAssert(legacyEntries.count > 1, @"Need more than 1 legacy entry for this test.");

    MWKSavedPageList* list = self.dataStore.userDataStore.savedPageList;

    // migration from legacy/unknown schema puts the last-saved entry first
    assertThat([list.entries valueForKeyPath:@"title.text"], contains(
                   @"Freemanbreen",
                   @"Glacier",
                   @"Crevasse",
                   @"Ice sheet", nil
                   ));

    expectResolution(^{
        // need to modify the list in order for it to save
        [list removeEntry:list.mostRecentEntry];
        return [list save];
    });

    // a migrated list should save as the current version
    MWKDataStore* dataStore2 = [[MWKDataStore alloc] initWithBasePath:self.dataStore.basePath];
    assertThat(dataStore2.savedPageListData, hasEntry(MWKSavedPageExportedSchemaVersionKey,
                                                      @(MWKSavedPageListSchemaVersionCurrent)));
    assertThat(dataStore2.userDataStore.savedPageList, is(equalTo(list)));
}

@end

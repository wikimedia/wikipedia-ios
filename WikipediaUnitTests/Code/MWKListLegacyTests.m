//
//  MWKSavedPageListLegacyTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "XCTestCase+DataStoreFixtureTesting.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageListDataExportConstants.h"
#import "Wikipedia-Swift.h"
#import "XCTestCase+PromiseKit.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKListLegacyTests : WMFAsyncTestCase
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
    
    XCTAssert(legacyEntries.count > 1, @"Need more than 1 legacy entry for this test.");

    MWKSavedPageList* list = self.dataStore.userDataStore.savedPageList;

    // migration from legacy/unknown schema puts the last-saved entry first
    assertThat([list.entries valueForKeyPath:@"url.wmf_title"], contains(
                   @"Freemanbreen",
                   @"Glacier",
                   @"Crevasse",
                   @"Ice sheet", nil
                   ));


    PushExpectation();
    [list removeEntry:list.mostRecentEntry];
    [list save].then(^(){
        [self popExpectationAfter:nil];
    }).catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });
    WaitForExpectations();

    // a migrated list should save as the current version
    MWKDataStore* dataStore2 = [[MWKDataStore alloc] initWithBasePath:self.dataStore.basePath];
    assertThat(dataStore2.savedPageListData, hasEntry(MWKSavedPageExportedSchemaVersionKey,
                                                      @(MWKSavedPageListSchemaVersionCurrent)));

    MWKSavedPageList* list2 = dataStore2.userDataStore.savedPageList;

    assertThat(list2, is(equalTo(list)));
}

@end

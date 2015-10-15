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
#import "Wikipedia-Swift.h"

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
    NSArray<MWKSavedPageEntry*>* legacyEntries = [[self.dataStore savedPageListData] bk_map:^id(NSDictionary* entryData) {
        MWKSavedPageEntry* entry;
        XCTAssertNoThrow((entry = [[MWKSavedPageEntry alloc] initWithDict:entryData]),
                         @"not expecting invalid entries for this test");
        return entry;
    }];
    NSAssert(legacyEntries.count > 1, @"Need more than 1 legacy entry for this test.");

    MWKSavedPageList* list = self.dataStore.userDataStore.savedPageList;

    assertThat(list.entries, is(equalTo([legacyEntries wmf_reverseArray])));
}

@end

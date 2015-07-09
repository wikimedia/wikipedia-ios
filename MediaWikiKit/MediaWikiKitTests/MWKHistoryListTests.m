//
//  MWKHistoryListTests.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"

@interface MWKHistoryListTests : MWKTestCase

@end

@implementation MWKHistoryListTests {
    MWKSite* siteEn;
    MWKSite* siteFr;
    MWKTitle* titleSFEn;
    MWKTitle* titleLAEn;
    MWKTitle* titleSFFr;
    MWKDataStore* dataStore;
    MWKHistoryList* historyList;
}

- (void)setUp {
    [super setUp];

    siteEn = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    siteFr = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];

    titleSFEn = [siteEn titleWithString:@"San Francisco"];
    titleLAEn = [siteEn titleWithString:@"Los Angeles"];
    titleSFFr = [siteFr titleWithString:@"San Francisco"];

    dataStore   = [MWKDataStore temporaryDataStore];
    historyList = [[MWKHistoryList alloc] initWithDataStore:dataStore];
    NSAssert([historyList length] == 0, @"History list must be empty before tests begin.");
}

- (void)tearDown {
    [dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testEmptyCount {
    XCTAssertEqual(historyList.length, 0, @"Should have length 0 initially");
}

- (void)testAddCount {
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                    discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:entry];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding");
}

- (void)testAddCount2 {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    XCTAssertEqual(historyList.length, 2, @"Should have length 2 after adding");
}

- (void)testAddCount2Same {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding a duplicate, not 2");
}

- (void)testAddCount2SameButDiffObjects {
    MWKTitle* title1 = [titleSFEn.site titleWithString:@"This is a title"];
    MWKTitle* title2 = [titleSFEn.site titleWithString:@"This is a title"];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:title1
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:title2
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding a duplicate, not 2");
}

- (void)testAddCount2DiffLanguages {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFFr
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    XCTAssertEqual(historyList.length, 2, @"Should have length 2 after adding a duplicate in another language, not 1");
}

- (void)testEmptyNotDirty {
    XCTAssertFalse(self->historyList.dirty, @"Should not be dirty initially");
}

- (void)testEmptyDirtyAfterAdd {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch]];
    XCTAssertTrue(historyList.dirty, @"Should be dirty after adding");
}

- (void)testAdd2ThenRemove {
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKHistoryEntry* entry2 = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:entry1];
    [historyList addEntry:entry2];
    [historyList removePageFromHistoryWithTitle:entry1.title];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding two then removing one");
}

@end

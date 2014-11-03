//
//  MWKHistoryListTests.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKTestCase.h"

@interface MWKHistoryListTests : MWKTestCase

@end

@implementation MWKHistoryListTests {
    MWKSite *siteEn;
    MWKSite *siteFr;
    MWKTitle *titleSFEn;
    MWKTitle *titleLAEn;
    MWKTitle *titleSFFr;
    MWKHistoryList *historyList;
}

- (void)setUp {
    [super setUp];

    siteEn = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    siteFr = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];

    titleSFEn = [siteEn titleWithString:@"San Francisco"];
    titleLAEn = [siteEn titleWithString:@"Los Angeles"];
    titleSFFr = [siteFr titleWithString:@"San Francisco"];

    historyList = [[MWKHistoryList alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testEmptyCount {
    XCTAssertEqual(historyList.length, 0, @"Should have length 0 initially");
}

- (void)testAddCount {
    MWKHistoryEntry *entry = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                    discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH];
    [historyList addEntry:entry];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding");
}

- (void)testAddCount2 {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    XCTAssertEqual(historyList.length, 2, @"Should have length 2 after adding");
}

- (void)testAddCount2Same {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding a duplicate, not 2");
}

- (void)testAddCount2DiffLanguages {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFFr
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    XCTAssertEqual(historyList.length, 2, @"Should have length 2 after adding a duplicate in another language, not 1");
}

- (void)testEmptyNotDirty {
    XCTAssertFalse(historyList.dirty, @"Should not be dirty initially");
}

- (void)testEmptyDirtyAfterAdd {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    XCTAssertTrue(historyList.dirty, @"Should be dirty after adding");
}

- (void)testEmptyNotDirtyAfterAddAndSave {
    [historyList addEntry:[[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH]];
    (void)[historyList dataExport];
    XCTAssertFalse(historyList.dirty, @"Should not be dirty after adding then exporting");
}

- (void)testAdd2ThenRemove {
    MWKHistoryEntry *entry1 = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                     discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH];
    MWKHistoryEntry *entry2 = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                     discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH];
    [historyList addEntry:entry1];
    [historyList addEntry:entry2];
    [historyList removeEntry:entry1];
    XCTAssertEqual(historyList.length, 1, @"Should have length 1 after adding two then removing one");
}



@end

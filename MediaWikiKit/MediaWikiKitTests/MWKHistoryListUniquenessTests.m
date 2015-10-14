//
//  MWKHistoryListTests.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "XCTestCase+PromiseKit.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKHistoryListUniquenessTests : MWKTestCase

@end

@implementation MWKHistoryListUniquenessTests {
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
    NSAssert([historyList countOfEntries] == 0, @"History list must be empty before tests begin.");
}

- (void)tearDown {
    [dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testInitialStateWithEmptyDataStore {
    XCTAssertEqual([historyList countOfEntries], 0, @"Should have length 0 initially");
    XCTAssertFalse(self->historyList.dirty, @"Should not be dirty initially");
}

- (void)testAddingOneEntry {
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                    discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:entry];
    assertThat(historyList.entries, is(@[entry]));
}

- (void)testAddingTwoDifferentTitles {
    MWKHistoryEntry* losAngeles = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                         discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKHistoryEntry* sanFrancisco = [[MWKHistoryEntry alloc] initWithTitle:titleSFFr
                                                           discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:losAngeles];
    [historyList addEntry:sanFrancisco];
    assertThat(historyList.entries, is(@[sanFrancisco, losAngeles]));
}

- (void)testStatePersistsWhenSaved {
    MWKHistoryEntry* losAngeles = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                         discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKHistoryEntry* sanFrancisco = [[MWKHistoryEntry alloc] initWithTitle:titleSFFr
                                                           discoveryMethod :MWKHistoryDiscoveryMethodSearch];

    /*
       HAX: dates are not precisely stored, so the difference must be >1s for the order to be persisted accurately.
       this shouldn't be a huge problem in practice because users (probably) won't save multiple pages in <1s
     */
    sanFrancisco.date = [NSDate dateWithTimeIntervalSinceNow:5];

    [historyList addEntry:losAngeles];
    [historyList addEntry:sanFrancisco];

    [self expectAnyPromiseToResolve:^AnyPromise*{
        return [self->historyList save];
    } timeout:WMFDefaultExpectationTimeout WMFExpectFromHere];

    XCTAssertFalse(historyList.dirty, @"Dirty flag should be reset after saving.");
    MWKHistoryList* persistedList = [[MWKHistoryList alloc] initWithDataStore:dataStore];

    // HAX: dates aren't exactly persisted, so we need to compare manually
    [persistedList.entries enumerateObjectsUsingBlock:^(MWKHistoryEntry* actualEntry, NSUInteger idx, BOOL* _) {
        MWKHistoryEntry* expectedEntry = self->historyList.entries[idx];
        assertThat(actualEntry.title, is(expectedEntry.title));
        assertThat(@(actualEntry.discoveryMethod), is(@(expectedEntry.discoveryMethod)));
        assertThat(@([actualEntry.date timeIntervalSinceDate:expectedEntry.date]), is(lessThanOrEqualTo(@1)));
    }];
}

- (void)testAddingIdenticalObjectUpdatesExistingEntryDate {
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                    discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    NSDate* previousDate = entry.date;
    [historyList addEntry:entry];
    [historyList addEntry:entry];
    assertThat(historyList.entries, is(@[entry]));
    assertThat([entry.date laterDate:previousDate], is(entry.date));
}

- (void)testAddingEquivalentObjectUpdatesExistingEntryDate {
    MWKTitle* title1        = [titleSFEn.site titleWithString:@"This is a title"];
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:title1
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKTitle* copyOfTitle1        = [titleSFEn.site titleWithString:@"This is a title"];
    MWKHistoryEntry* copyOfEntry1 = [[MWKHistoryEntry alloc] initWithTitle:copyOfTitle1
                                                           discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:entry1];
    [historyList addEntry:copyOfEntry1];
    assertThat(historyList.entries, is(@[entry1]));
    assertThat(entry1.date, is(copyOfEntry1.date));
}

- (void)testAddingTheSameTitleFromDifferentSites {
    MWKHistoryEntry* en = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKHistoryEntry* fr = [[MWKHistoryEntry alloc] initWithTitle:titleSFFr
                                                 discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:en];
    [historyList addEntry:fr];
    assertThat([historyList entries], is(@[fr, en]));
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
    [historyList removeEntryWithListIndex:entry1.title];
    assertThat([historyList entries], is(@[entry2]));
}

- (void)testListOrdersByDateDescending {
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKHistoryEntry* entry2 = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:entry1];
    [historyList addEntry:entry2];
    NSAssert([[entry2.date laterDate:entry1.date] isEqualToDate:entry2.date],
             @"Test assumes new entries are created w/ the current date.");
    assertThat([historyList entries], is(@[entry2, entry1]));
    assertThat([historyList mostRecentEntry], is(entry2));
}

- (void)testListOrderAfterAddingSameEntry {
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    MWKHistoryEntry* entry2 = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn
                                                     discoveryMethod :MWKHistoryDiscoveryMethodSearch];
    [historyList addEntry:entry1];
    NSDate* initialDate = entry1.date;
    [historyList addEntry:entry2];
    [historyList addEntry:entry1];
    NSDate* updatedDate = entry1.date;
    assertThat([initialDate laterDate:updatedDate], is(updatedDate));
    assertThat([historyList entries], is(@[entry1, entry2]));
    XCTAssertTrue(historyList.dirty);
}

@end

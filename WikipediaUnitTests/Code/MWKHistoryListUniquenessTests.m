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
#import "MWKList+Subclass.h"

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

- (void)testStatePersistsWhenSaved {
    MWKHistoryEntry* losAngeles = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn];
    MWKHistoryEntry* sanFrancisco = [[MWKHistoryEntry alloc] initWithTitle:titleSFFr];

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
        assertThat(@([actualEntry.date timeIntervalSinceDate:expectedEntry.date]), is(lessThanOrEqualTo(@1)));
    }];
}

- (void)testAddingIdenticalObjectUpdatesExistingEntryDate {
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn];
    NSDate* previousDate = entry.date;
    [historyList addEntry:entry];
    [historyList addEntry:entry];
    assertThat(historyList.entries, is(@[entry]));
    assertThat([entry.date laterDate:previousDate], is(entry.date));
}

- (void)testAddingEquivalentObjectUpdatesExistingEntryDate {
    MWKTitle* title1        = [titleSFEn.site titleWithString:@"This is a title"];
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:title1];
    MWKTitle* copyOfTitle1        = [titleSFEn.site titleWithString:@"This is a title"];
    MWKHistoryEntry* copyOfEntry1 = [[MWKHistoryEntry alloc] initWithTitle:copyOfTitle1];
    [historyList addEntry:entry1];
    [historyList addEntry:copyOfEntry1];
    assertThat(historyList.entries, equalTo(@[copyOfEntry1]));
    assertThat([historyList mostRecentEntry].date, equalTo(copyOfEntry1.date));
}

- (void)testAddingTheSameTitleFromDifferentSites {
    MWKHistoryEntry* en = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn];
    MWKHistoryEntry* fr = [[MWKHistoryEntry alloc] initWithTitle:titleSFFr];
    [historyList addEntry:en];
    [historyList addEntry:fr];
    assertThat([historyList entries], is(@[fr, en]));
}

- (void)testListOrdersByDateDescending {
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn];
    MWKHistoryEntry* entry2 = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn];
    [historyList addEntry:entry1];
    [historyList addEntry:entry2];
    NSAssert([[entry2.date laterDate:entry1.date] isEqualToDate:entry2.date],
             @"Test assumes new entries are created w/ the current date.");
    assertThat([historyList entries], is(@[entry2, entry1]));
    assertThat([historyList mostRecentEntry], is(entry2));
}

- (void)testListOrderAfterAddingSameEntry {
    MWKHistoryEntry* entry1 = [[MWKHistoryEntry alloc] initWithTitle:titleSFEn];
    entry1.date = [[NSDate date] dateByAddingTimeInterval:-60]; //the past
    MWKHistoryEntry* entry2 = [[MWKHistoryEntry alloc] initWithTitle:titleLAEn];
    [historyList addEntry:entry1];
    [historyList addEntry:entry2];
    assertThat([historyList entries], is(@[entry2, entry1])); //ordered by date
    [historyList addEntry:entry1];
    assertThat([historyList entries], is(@[entry2, entry1])); //ordered by date
    XCTAssertTrue(historyList.dirty);
}

@end

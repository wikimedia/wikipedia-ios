//
//  MWKHistoryListCorruptDataTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKHistoryListCorruptDataTests : XCTestCase
@property (strong, nonatomic) MWKHistoryList* historyList;

@end

@implementation MWKHistoryListCorruptDataTests

- (void)testPrunesEntriesWithEmptyOrAbsentTitles {
    MWKHistoryEntry* validEntry =
        [[MWKHistoryEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]
                               discoveryMethod :MWKHistoryDiscoveryMethodLink];

    NSDictionary* validEntryExport = [validEntry dataExport];

    NSDictionary* absentTitleExport = ^{
        NSMutableDictionary* d = [validEntryExport mutableCopy];
        [d removeObjectForKey:@"title"];
        return [d copy];
    } ();

    NSDictionary* emptyTitleExport = ^{
        NSMutableDictionary* d = [validEntryExport mutableCopy];
        d[@"title"] = @"";
        return [d copy];
    } ();

    MWKHistoryList* list;
    XCTAssertNoThrow((list = [[MWKHistoryList alloc] initWithDict:@{
                                  @"entries": @[validEntryExport, absentTitleExport, emptyTitleExport]
                              }]));

    assertThat(@(list.length), is(@1));
    // TODO: change to comparison when date equality is fixed...
    assertThat([[list mostRecentEntry] dataExport], is(equalTo([validEntry dataExport])));
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testIgnoresInvalidEntries {
    MWKHistoryList* list = [MWKHistoryList new];

    MWKHistoryEntry* validEntry =
        [[MWKHistoryEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]
                               discoveryMethod :MWKHistoryDiscoveryMethodLink];

    [list addEntry:validEntry];

    void (^ assertUnaltered)() = ^{
        assertThat(@(list.length), is(@1));
        assertThat(list.mostRecentEntry, is(validEntry));
    };

    MWKHistoryEntry* nilEntry =
        [[MWKHistoryEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:nil]
                               discoveryMethod :MWKHistoryDiscoveryMethodLink];

    MWKHistoryEntry* emptyEntry =
        [[MWKHistoryEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@""]
                               discoveryMethod :MWKHistoryDiscoveryMethodLink];

    NSArray* invalidEntries = @[nilEntry, emptyEntry];

    for (MWKHistoryEntry* invalidEntry in invalidEntries) {
        XCTAssertNoThrow(([list addEntry:invalidEntry]));
        assertUnaltered();
        XCTAssertNoThrow(([list removeEntry:invalidEntry]));
        assertUnaltered();
    }
}

#pragma clang diagnostic pop

- (void)testIgnoresNil {
    MWKHistoryList* list = [MWKHistoryList new];

    MWKHistoryEntry* validEntry =
        [[MWKHistoryEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]
                               discoveryMethod :MWKHistoryDiscoveryMethodLink];

    [list addEntry:validEntry];

    void (^ assertUnaltered)() = ^{
        assertThat(@(list.length), is(@1));
        assertThat(list.mostRecentEntry, is(validEntry));
    };

    XCTAssertNoThrow(([list addEntry:nil]));
    assertUnaltered();
    XCTAssertNoThrow(([list removeEntry:nil]));
    assertUnaltered();
}

@end

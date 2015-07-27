//
//  MWKSavedPageListCorruptDataTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"


#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListCorruptDataTests : XCTestCase

@end

@implementation MWKSavedPageListCorruptDataTests

- (void)testPrunesEntriesWithEmptyOrAbsentTitles {
    MWKSavedPageEntry* validEntry =
        [[MWKSavedPageEntry alloc] initWithTitle:
         [[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]];

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

    MWKSavedPageList* list;
    XCTAssertNoThrow((list = [[MWKSavedPageList alloc] initWithDict:@{
                                  @"entries": @[validEntryExport, absentTitleExport, emptyTitleExport]
                              }]));

    assertThat(@(list.length), is(@1));
    // TODO: change to comparison when date equality is fixed...
    assertThat([[list entryAtIndex:0] dataExport], is(equalTo([validEntry dataExport])));
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testIgnoresInvalidEntries {
    MWKSavedPageList* list = [MWKSavedPageList new];

    MWKSavedPageEntry* validEntry =
        [[MWKSavedPageEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]];

    [list addEntry:validEntry];

    void (^ assertUnaltered)() = ^{
        assertThat(@(list.length), is(@1));
        assertThat([list entryAtIndex:0], is(validEntry));
    };

    MWKSavedPageEntry* nilEntry =
        [[MWKSavedPageEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:nil]];

    MWKSavedPageEntry* emptyEntry =
        [[MWKSavedPageEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@""]];

    NSArray* invalidEntries = @[nilEntry, emptyEntry];

    for (MWKSavedPageEntry* invalidEntry in invalidEntries) {
        XCTAssertNoThrow(([list addEntry:invalidEntry]));
        assertUnaltered();
        XCTAssertNoThrow(([list removeEntry:invalidEntry]));
        assertUnaltered();
    }
}

#pragma clang diagnostic pop

- (void)testIgnoresNil {
    MWKSavedPageList* list = [MWKSavedPageList new];

    MWKSavedPageEntry* validEntry =
        [[MWKSavedPageEntry alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]];

    [list addEntry:validEntry];

    void (^ assertUnaltered)() = ^{
        assertThat(@(list.length), is(@1));
        assertThat([list entryAtIndex:0], is(validEntry));
    };

    XCTAssertNoThrow(([list addEntry:nil]));
    assertUnaltered();
    XCTAssertNoThrow(([list removeEntry:nil]));
    assertUnaltered();
}

@end

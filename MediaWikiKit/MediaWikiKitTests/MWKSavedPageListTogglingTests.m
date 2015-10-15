//
//  MWKSavedPageListTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSavedPageEntry+Random.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListTogglingTests : XCTestCase
@property (nonatomic, strong) MWKSavedPageList* list;
@end

@implementation MWKSavedPageListTogglingTests

- (void)setUp {
    self.list = [[MWKSavedPageList alloc] init];
}

#pragma mark - Manual Saving

- (void)testAddedTitlesArePrepended {
    MWKSavedPageEntry* e1 = [MWKSavedPageEntry random];
    MWKSavedPageEntry* e2 = [MWKSavedPageEntry random];
    [self.list addEntry:e1];
    [self.list addEntry:e2];
    assertThat(self.list.entries, is(@[e2, e1]));
    assertThat(self.list.mostRecentEntry, is(e2));
}

- (void)testAddingExistingSavedPageIsIgnored {
    MWKSavedPageEntry* entry = [MWKSavedPageEntry random];
    [self.list addEntry:entry];
    [self.list addEntry:[[MWKSavedPageEntry alloc] initWithTitle:entry.title]];
    assertThat(self.list.entries, is(@[entry]));
}

#pragma mark - Toggling

- (void)testTogglingSavedPageReturnsNoAndRemovesFromList {
    MWKSavedPageEntry* savedEntry = [MWKSavedPageEntry random];
    [self.list addEntry:savedEntry];
    [self.list toggleSavedPageForTitle:savedEntry.title];
    XCTAssertFalse([self.list isSaved:savedEntry.title]);
    XCTAssertNil([self.list entryForListIndex:savedEntry.title]);
}

- (void)testToggleUnsavedPageReturnsYesAndAddsToList {
    MWKSavedPageEntry* unsavedEntry = [MWKSavedPageEntry random];
    [self.list toggleSavedPageForTitle:unsavedEntry.title];
    XCTAssertTrue([self.list isSaved:unsavedEntry.title]);
    XCTAssertEqualObjects([self.list entryForListIndex:unsavedEntry.title], unsavedEntry);
}

- (void)testTogglePageWithEmptyTitleReturnsNilWithError {
    MWKTitle* emptyTitle = MKTMock([MWKTitle class]);
    [MKTGiven([emptyTitle text]) willReturn:@""];
    [self.list toggleSavedPageForTitle:emptyTitle];
    XCTAssertFalse([self.list isSaved:emptyTitle]);
}

@end

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
#import "MWKSavedPageEntry.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface MWKSavedPageListTogglingTests : XCTestCase
@property (nonatomic, strong) MWKSavedPageList* list;
@end

@implementation MWKSavedPageListTogglingTests

- (void)setUp {
    self.list = [[MWKSavedPageList alloc] init];
}

- (MWKSavedPageEntry*)entryWithTitleText:(NSString*)titleText {
    MWKTitle* title =
        [[MWKTitle alloc] initWithSite:[MWKSite siteWithCurrentLocale] normalizedTitle:titleText fragment:nil];
    return [[MWKSavedPageEntry alloc] initWithTitle:title];
}

- (void)testTogglingSavedPageReturnsNoAndRemovesFromList {
    MWKSavedPageEntry* savedEntry = [self entryWithTitleText:@"foo"];
    [self.list addEntry:savedEntry];
    [self.list toggleSavedPageForTitle:savedEntry.title];
    XCTAssertFalse([self.list isSaved:savedEntry.title]);
    XCTAssertNil([self.list entryForListIndex:savedEntry.title]);
}

- (void)testToggleUnsavedPageReturnsYesAndAddsToList {
    MWKSavedPageEntry* unsavedEntry = [self entryWithTitleText:@"foo"];
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

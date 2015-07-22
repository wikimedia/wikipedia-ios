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

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface MWKSavedPageListTests : XCTestCase
@property (nonatomic, strong) MWKSavedPageList* list;
@end

@implementation MWKSavedPageListTests

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
    NSError* saveError;
    NSNumber* postToggleSaveState = [self.list toggleSaveStateForTitle:savedEntry.title error:&saveError];
    XCTAssertNil(saveError);
    XCTAssertFalse(postToggleSaveState.boolValue);
    XCTAssertNil([self.list entryForTitle:savedEntry.title]);
}

- (void)testToggleUnsavedPageReturnsYesAndAddsToList {
    MWKSavedPageEntry* unsavedEntry = [self entryWithTitleText:@"foo"];
    NSError* toggleError;
    NSNumber* postToggleSaveState = [self.list toggleSaveStateForTitle:unsavedEntry.title error:&toggleError];
    XCTAssertNil(toggleError);
    XCTAssertTrue(postToggleSaveState.boolValue);
    XCTAssertEqualObjects([self.list entryForTitle:unsavedEntry.title], unsavedEntry);
}

- (void)testTogglePageWithNilTitleReturnsNilWithError {
    NSError* toggleError;
    NSNumber* postToggleSaveState = [self.list toggleSaveStateForTitle:nil error:&toggleError];
    XCTAssertNil(postToggleSaveState);
    XCTAssertEqual(toggleError.code, MWKEmptyTitleError);
}

- (void)testTogglePageWithEmptyTitleReturnsNilWithError {
    MWKTitle* emptyTitle = mock([MWKTitle class]);
    [given([emptyTitle text]) willReturn:@""];
    NSError* toggleError;
    NSNumber* postToggleSaveState = [self.list toggleSaveStateForTitle:emptyTitle error:&toggleError];
    XCTAssertNil(postToggleSaveState);
    XCTAssertEqual(toggleError.code, MWKEmptyTitleError);
}

@end

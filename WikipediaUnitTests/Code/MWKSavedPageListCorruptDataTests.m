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
#import "MWKSite.h"
#import "MWKTitle.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListCorruptDataTests : XCTestCase

@end

@implementation MWKSavedPageListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyOrAbsentTitles {
    MWKSavedPageList* list = [[MWKSavedPageList alloc] initWithEntries:nil];
    [list addSavedPageWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"Foo"]];
    assertThat(@([list countOfEntries]), is(@1));

    [list addSavedPageWithTitle:nil];
    assertThat(@([list countOfEntries]), is(@1));

    [list addSavedPageWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@""]];
    assertThat(@([list countOfEntries]), is(@1));
}

#pragma clang diagnostic pop


@end

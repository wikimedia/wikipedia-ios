//
//  WMFSearchResultCellVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBSnapshotTestCase+WMFConvenience.h"
#import "WMFSearchResultCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIView+VisualTestSizingUtils.h"
#import "MWKTitle.h"

static NSString* const ShortSearchResultTitle = @"One line title";

static NSString* const MediumSearchResultTitle = @"This is a moderately long title that should take up two lines.";

static NSString* const LongSearchResultTitle =
    @"This is an excessively lengthy title that I wrote for testing, which should take up three lines of text"
    " (at the very least).";

static NSString* const ShortSearchResultDescription = @"One line description";

static NSString* const LongSearchResultDescription =
    @"This description describes a search result, and should take approximately three lines to display.";

@interface WMFSearchResultCellVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFSearchResultCell* searchResultCell;
@end

@implementation WMFSearchResultCellVisualTests

- (void)setUp {
    [super setUp];
    self.searchResultCell = [WMFSearchResultCell wmf_viewFromClassNib];
//    self.recordMode       = YES;
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Short title, short description

- (void)testShouldShowTitleAtTheTopAndDescriptionAtTheBottom {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

#pragma mark - Long title, short description

- (void)testShouldShowDescriptionWhenTitleIsTwoLines {
    [self populateTitleLabelWithString:MediumSearchResultTitle
                           searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldCollapseDescriptionWhenTitleExceedsTwoLines {
    [self populateTitleLabelWithString:LongSearchResultTitle
                           searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldTruncateAndShrinkTitleAtFourLines {
    NSString* reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

#pragma mark - Long title, long description

- (void)testShouldNotShowLongDescriptionWhenTitleExceedsTwoLines {
    NSString* reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:reallyLongString];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

#pragma mark - Short title, long desription

- (void)testShouldTruncateLongDescriptionAndNotCollapseTitle {
    NSString* reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:MediumSearchResultTitle searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:reallyLongString];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldExpandDescriptionToMultipleLines {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:LongSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

#pragma mark - Title Highlighting

- (void)testShouldHighlightMatchingSubstring {
    NSString* mediumTitleSubstring =
        [MediumSearchResultTitle substringToIndex:MediumSearchResultTitle.length * 0.3];
    [self populateTitleLabelWithString:MediumSearchResultTitle searchQuery:mediumTitleSubstring];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

#pragma mark - Test Utils

- (void)populateTitleLabelWithString:(NSString*)titleText searchQuery:(NSString*)query {
    NSURL* titleURL =
        [NSURL URLWithString:[NSString stringWithFormat:@"//en.wikipedia.org/wiki/%@",
                              [titleText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    [self.searchResultCell setTitle:[[MWKTitle alloc] initWithURL:titleURL]
              highlightingSubstring:query];
}

@end

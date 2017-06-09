#import "FBSnapshotTestCase+WMFConvenience.h"
#import "WMFArticleListTableViewCell.h"
#import "WMFArticleListTableViewCell+WMFSearch.h"
#import "UIView+WMFDefaultNib.h"
#import "UIView+VisualTestSizingUtils.h"

static NSString *const ShortSearchResultTitle = @"One line title";

static NSString *const MediumSearchResultTitle = @"This is a moderately long title that should take up two lines.";

static NSString *const LongSearchResultTitle =
    @"This is an excessively lengthy title that I wrote for testing, which should take up three lines of text"
     " (at the very least).";

static NSString *const ShortSearchResultDescription = @"One line description";

static NSString *const LongSearchResultDescription =
    @"This description describes a search result, and should take approximately three lines to display.";

@interface WMFArticleListCellVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFArticleListTableViewCell *searchResultCell;
@end

@implementation WMFArticleListCellVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = [[NSUserDefaults wmf_userDefaults] wmf_visualTestBatchRecordMode];
    self.deviceAgnostic = YES;
    self.searchResultCell = [WMFArticleListTableViewCell wmf_viewFromClassNib];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testShouldShowTitleAtTheTopAndDescriptionAtTheBottom {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setDescriptionText:ShortSearchResultDescription];
    [self wmf_verifyView:self.searchResultCell width:320.f];
}

- (void)testShouldCenterShortTitleWhenDescriptionIsEmpty {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setDescriptionText:nil];
    [self wmf_verifyView:self.searchResultCell width:320.f];
}

- (void)testShouldTruncateAndShrinkTitle {
    NSString *reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    [self.searchResultCell setDescriptionText:ShortSearchResultDescription];
    [self wmf_verifyView:self.searchResultCell width:320.f];
}

- (void)testShouldNotShowLongDescriptionWhenTitleExceedsTwoLines {
    NSString *reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    [self.searchResultCell setDescriptionText:reallyLongString];
    [self wmf_verifyView:self.searchResultCell width:320.f];
}

- (void)testShouldShowLongDescriptionWhenTitleIsShort {
    NSString *reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setDescriptionText:reallyLongString];
    [self wmf_verifyView:self.searchResultCell width:320.f];
}

- (void)testShouldHighlightMatchingSubstring {
    NSString *mediumTitleSubstring =
        [MediumSearchResultTitle substringToIndex:MediumSearchResultTitle.length * 0.3];
    [self populateTitleLabelWithString:MediumSearchResultTitle searchQuery:mediumTitleSubstring];
    [self.searchResultCell setDescriptionText:ShortSearchResultDescription];
    [self wmf_verifyView:self.searchResultCell width:320.f];
}

#pragma mark - Test Utils

- (void)populateTitleLabelWithString:(NSString *)titleText searchQuery:(NSString *)query {
    [self.searchResultCell wmf_setTitleText:titleText highlightingText:query];
}

@end

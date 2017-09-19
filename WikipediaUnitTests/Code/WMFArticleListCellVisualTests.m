#import "FBSnapshotTestCase+WMFConvenience.h"
#import "UIView+WMFDefaultNib.h"
#import "UIView+VisualTestSizingUtils.h"
#import "Wikipedia-Swift.h"

static NSString *const ShortSearchResultTitle = @"One line title";

static NSString *const MediumSearchResultTitle = @"This is a moderately long title that should take up two lines.";

static NSString *const LongSearchResultTitle =
    @"This is an excessively lengthy title that I wrote for testing, which should take up three lines of text"
     " (at the very least).";

static NSString *const ShortSearchResultDescription = @"One line description";

static NSString *const LongSearchResultDescription =
    @"This description describes a search result, and should take approximately three lines to display.";

@interface WMFArticleListCellVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFArticleCollectionViewCell *searchResultCell;
@end

@implementation WMFArticleListCellVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = WMFIsVisualTestRecordModeEnabled;
    self.deviceAgnostic = YES;
    self.searchResultCell = [[WMFArticleRightAlignedImageCollectionViewCell alloc] init];
    [self.searchResultCell configureForCompactListAt:0];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testShouldShowTitleAtTheTopAndDescriptionAtTheBottom {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    self.searchResultCell.descriptionLabel.text = ShortSearchResultDescription;
    [self wmf_verifyView:self.searchResultCell];
}

- (void)testShouldCenterShortTitleWhenDescriptionIsEmpty {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    self.searchResultCell.descriptionLabel.text = nil;
    [self wmf_verifyView:self.searchResultCell];
}

- (void)testShouldTruncateAndShrinkTitle {
    NSString *reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    self.searchResultCell.descriptionLabel.text = ShortSearchResultDescription;
    [self wmf_verifyView:self.searchResultCell];
}

- (void)testShouldNotShowLongDescriptionWhenTitleExceedsTwoLines {
    NSString *reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    self.searchResultCell.descriptionLabel.text = reallyLongString;
    [self wmf_verifyView:self.searchResultCell];
}

- (void)testShouldShowLongDescriptionWhenTitleIsShort {
    NSString *reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    self.searchResultCell.descriptionLabel.text = reallyLongString;
    [self wmf_verifyView:self.searchResultCell];
}

- (void)testShouldHighlightMatchingSubstring {
    NSString *mediumTitleSubstring =
        [MediumSearchResultTitle substringToIndex:MediumSearchResultTitle.length * 0.3];
    [self populateTitleLabelWithString:MediumSearchResultTitle searchQuery:mediumTitleSubstring];
    self.searchResultCell.descriptionLabel.text = ShortSearchResultDescription;
    [self wmf_verifyView:self.searchResultCell];
}

#pragma mark - Test Utils

- (void)populateTitleLabelWithString:(NSString *)titleText searchQuery:(NSString *)query {
    [self.searchResultCell setTitleText:titleText highlightingText:query locale:nil];
}

@end

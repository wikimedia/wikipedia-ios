
#import "WMFFeaturedArticleSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFEnglishFeaturedTitleFetcher.h"

#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSearchResult.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "WMFArticlePlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"
#import "WMFSaveButtonController.h"

#import "NSDateFormatter+WMFExtensions.h"
#import "UIColor+WMFHexColor.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFFeaturedArticleSectionIdentifierPrefix = @"WMFFeaturedArticleSectionIdentifier";

@interface WMFFeaturedArticleSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) NSDate* date;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) WMFEnglishFeaturedTitleFetcher* featuredTitlePreviewFetcher;

@property (nonatomic, strong, nullable) MWKSearchResult* featuredArticlePreview;

@end

@implementation WMFFeaturedArticleSectionController

- (instancetype)initWithSite:(MWKSite*)site date:(NSDate*)date savedPageList:(MWKSavedPageList*)savedPageList {
    NSParameterAssert(site);
    NSParameterAssert(date);
    self = [super init];
    if (self) {
        self.site          = site;
        self.date          = date;
        self.savedPageList = savedPageList;
    }
    return self;
}

#pragma mark - Accessors

- (WMFEnglishFeaturedTitleFetcher*)featuredTitlePreviewFetcher {
    if (_featuredTitlePreviewFetcher == nil) {
        _featuredTitlePreviewFetcher = [[WMFEnglishFeaturedTitleFetcher alloc] init];
    }
    return _featuredTitlePreviewFetcher;
}

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return dateFormatter;
}

#pragma mark - WMFBaseExploreSectionController

- (id)sectionIdentifier {
    return [WMFFeaturedArticleSectionIdentifierPrefix stringByAppendingString:self.date.description];
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_colorWithHex:0xE6B84F alpha:1.0];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_colorWithHex:0xFCF5E4 alpha:1.0];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-featured-article-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString*)cellIdentifier {
    return [WMFArticlePreviewTableViewCell identifier];
}

- (UINib*)cellNib {
    return [WMFArticlePreviewTableViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 1;
}

- (nullable NSString*)placeholderCellIdentifier {
    return [WMFArticlePlaceholderTableViewCell identifier];
}

- (nullable UINib*)placeholderCellNib {
    return [WMFArticlePlaceholderTableViewCell wmf_classNib];
}

- (void)configureCell:(WMFArticlePreviewTableViewCell*)cell withItem:(MWKSearchResult*)item atIndexPath:(NSIndexPath*)indexPath {
    cell.titleText       = item.displayTitle;
    cell.descriptionText = item.wikidataDescription;
    cell.snippetText     = item.extract;
    [cell setImageURL:item.thumbnailURL];
    [cell setSaveableTitle:[self titleForItemAtIndexPath:indexPath] savedPageList:self.savedPageList];
    [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
    cell.saveButtonController.analyticsSource = self;
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticlePreviewTableViewCell estimatedRowHeight];
}

- (NSString*)analyticsName {
    return @"Featured Article";
}

- (AnyPromise*)fetchData {
    @weakify(self);
    return [self.featuredTitlePreviewFetcher fetchFeaturedArticlePreviewForDate:self.date].then(^(MWKSearchResult* data) {
        @strongify(self);
        self.featuredArticlePreview = data;
        return @[self.featuredArticlePreview];
    }).catch(^(NSError* error){
        @strongify(self);
        self.featuredArticlePreview = nil;
        return error;
    });
}

#pragma mark - WMFTitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [[MWKTitle alloc] initWithSite:self.site normalizedTitle:self.featuredArticlePreview.displayTitle fragment:nil];
}

@end

NS_ASSUME_NONNULL_END

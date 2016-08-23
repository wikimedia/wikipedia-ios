#import "WMFFeaturedArticleSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFEnglishFeaturedTitleFetcher.h"

#import "MWKSearchResult.h"

#import "WMFArticlePreviewCollectionViewCell.h"
#import "WMFArticlePlaceholderCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

#import "NSDateFormatter+WMFExtensions.h"
#import "UIColor+WMFHexColor.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFFeaturedArticleSectionIdentifierPrefix = @"WMFFeaturedArticleSectionIdentifier";

@interface WMFFeaturedArticleSectionController ()

@property (nonatomic, strong, readwrite) NSURL *siteURL;
@property (nonatomic, strong, readwrite) NSDate *date;

@property (nonatomic, strong) WMFEnglishFeaturedTitleFetcher *featuredTitlePreviewFetcher;

@property (nonatomic, strong, nullable) MWKSearchResult *featuredArticlePreview;

@end

@implementation WMFFeaturedArticleSectionController

- (instancetype)initWithSiteURL:(NSURL *)url
                           date:(NSDate *)date
                      dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(url);
    NSParameterAssert(date);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.siteURL = url;
        self.date = date;
    }
    return self;
}

#pragma mark - Accessors

- (WMFEnglishFeaturedTitleFetcher *)featuredTitlePreviewFetcher {
    if (_featuredTitlePreviewFetcher == nil) {
        _featuredTitlePreviewFetcher = [[WMFEnglishFeaturedTitleFetcher alloc] init];
    }
    return _featuredTitlePreviewFetcher;
}

#pragma mark - WMFBaseExploreSectionController

- (id)sectionIdentifier {
    return [WMFFeaturedArticleSectionIdentifierPrefix stringByAppendingString:self.date.description];
}

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_colorWithHex:0xE6B84F alpha:1.0];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_colorWithHex:0xFCF5E4 alpha:1.0];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-featured-article-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)cellIdentifier {
    return [WMFArticlePreviewCollectionViewCell identifier];
}

- (UINib *)cellNib {
    return [WMFArticlePreviewCollectionViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 1;
}

- (nullable NSString *)placeholderCellIdentifier {
    return [WMFArticlePlaceholderCollectionViewCell identifier];
}

- (nullable UINib *)placeholderCellNib {
    return [WMFArticlePlaceholderCollectionViewCell wmf_classNib];
}

- (void)configureCell:(WMFArticlePreviewCollectionViewCell *)cell withItem:(MWKSearchResult *)item atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = item.displayTitle;
    cell.descriptionText = item.wikidataDescription;
    cell.snippetText = item.extract;
    [cell setImageURL:item.thumbnailURL];
    [cell setSaveableURL:[self urlForItemAtIndexPath:indexPath] savedPageList:self.savedPageList];
    cell.saveButtonController.analyticsContext = self;
    cell.saveButtonController.analyticsContentType = self;
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticlePreviewCollectionViewCell estimatedRowHeight];
}

- (NSString *)analyticsContentType {
    return @"Featured";
}

- (AnyPromise *)fetchData {
    @weakify(self);
    return [self.featuredTitlePreviewFetcher fetchFeaturedArticlePreviewForDate:self.date].then(^(MWKSearchResult *data) {
                                                                                              @strongify(self);
                                                                                              if (!self) {
                                                                                                  return (id)[AnyPromise promiseWithValue:[NSError cancelledError]];
                                                                                              }
                                                                                              self.featuredArticlePreview = data;
                                                                                              return (id) @[data];
                                                                                          })
        .catch(^(NSError *error) {
            @strongify(self);
            self.featuredArticlePreview = nil;
            return error;
        });
}

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self urlForItemAtIndexPath:indexPath];
    return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
}

- (BOOL)prefersWiderColumn {
    return YES;
}

#pragma mark - WMFTitleProviding

- (nullable NSURL *)urlForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.siteURL wmf_URLWithTitle:self.featuredArticlePreview.displayTitle];
}

@end

NS_ASSUME_NONNULL_END

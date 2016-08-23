#import "WMFMainPageSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticlePreviewFetcher.h"

#import "MWKDataStore.h"
#import "MWKUserDataStore.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

#import "WMFArticleListCollectionViewCell.h"
#import "WMFMainPagePlaceholderCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "NSDateFormatter+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFMainPageSectionIdentifier = @"WMFMainPageSectionIdentifier";

@interface WMFMainPageSectionController ()

@property (nonatomic, strong, readwrite) NSURL *siteURL;

@property (nonatomic, strong) MWKSiteInfoFetcher *siteInfoFetcher;

@property (nonatomic, strong) WMFArticlePreviewFetcher *titleSearchFetcher;

@property (nonatomic, strong, nullable) MWKSiteInfo *siteInfo;

@property (nonatomic, strong, nullable) MWKSearchResult *mainPageSearchResult;

@end

@implementation WMFMainPageSectionController

- (instancetype)initWithSiteURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(url);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.siteURL = url;
    }
    return self;
}

#pragma mark - Accessors

- (MWKSiteInfoFetcher *)siteInfoFetcher {
    if (_siteInfoFetcher == nil) {
        _siteInfoFetcher = [[MWKSiteInfoFetcher alloc] init];
    }
    return _siteInfoFetcher;
}

- (WMFArticlePreviewFetcher *)titleSearchFetcher {
    if (_titleSearchFetcher == nil) {
        _titleSearchFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _titleSearchFetcher;
}

#pragma mark - HomeSectionController

- (id)sectionIdentifier {
    return WMFMainPageSectionIdentifier;
}

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"news-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-main-page-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:[NSDate date]] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)cellIdentifier {
    return [WMFArticleListCollectionViewCell identifier];
}

- (UINib *)cellNib {
    return [WMFArticleListCollectionViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 1;
}

- (nullable NSString *)placeholderCellIdentifier {
    return [WMFMainPagePlaceholderCollectionViewCell identifier];
}

- (nullable UINib *)placeholderCellNib {
    return [WMFMainPagePlaceholderCollectionViewCell wmf_classNib];
}

- (void)configureCell:(WMFArticleListCollectionViewCell *)cell withItem:(MWKSearchResult *)item atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = item.displayTitle;
    cell.titleLabel.accessibilityLanguage = self.siteURL.wmf_language;
    cell.descriptionText = item.wikidataDescription;
    [cell setImageURL:item.thumbnailURL];
}

- (NSString *)analyticsContentType {
    return @"Main Page";
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticleListCollectionViewCell estimatedRowHeight];
}

- (AnyPromise *)fetchData {
    @weakify(self);
    return [self.siteInfoFetcher fetchSiteInfoForSiteURL:self.siteURL].then(^(MWKSiteInfo *data) {
                                                                          @strongify(self);
                                                                          if (!self || !data.mainPageURL) {
                                                                              return (id)[AnyPromise promiseWithValue:[NSError cancelledError]];
                                                                          }
                                                                          self.siteInfo = data;
                                                                          return (id)[self.titleSearchFetcher fetchArticlePreviewResultsForArticleURLs:@[self.siteInfo.mainPageURL] siteURL:self.siteURL];
                                                                      })
        .then(^(NSArray<MWKSearchResult *> *searchResults) {
            @strongify(self);
            if (!self) {
                return (id)[AnyPromise promiseWithValue:[NSError cancelledError]];
            }
            self.mainPageSearchResult = [searchResults firstObject];
            return (id) @[[searchResults firstObject]];
        })
        .catch(^(NSError *error) {
            @strongify(self);
            self.siteInfo = nil;
            self.mainPageSearchResult = nil;
            return error;
        });
}

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self urlForItemAtIndexPath:indexPath];
    return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
}

#pragma mark - WMFTitleProviding

- (nullable NSURL *)urlForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.siteInfo mainPageURL];
}

@end

NS_ASSUME_NONNULL_END

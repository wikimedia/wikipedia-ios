#import "WMFMostReadSectionController.h"
#import "Wikipedia-Swift.h"

#import "UIScreen+WMFImageWidth.h"
#import "WMFArticlePreviewFetcher.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "WMFArticleListCollectionViewCell.h"
#import "MWKSearchResult.h"
#import "WMFArticleViewController.h"
#import "WMFMostReadTitleFetcher.h"
#import "WMFMostReadTitlesResponse.h"
#import "NSDate+Utilities.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFMainPagePlaceholderCollectionViewCell.h"
#import "Wikipedia-Swift.h"
#import "NSNumber+MWKTitleNamespace.h"
#import <Tweaks/FBTweakInline.h>
#import "WMFMostReadListTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadSectionController ()

@property (nonatomic, copy, readwrite) NSURL *siteURL;
@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, strong, readonly) NSString *localDateDisplayString;
@property (nonatomic, strong, readonly) NSString *localDateShortDisplayString;

@property (nonatomic, strong, nullable, readwrite) WMFMostReadTitlesResponseItem *mostReadArticlesResponse;
@property (nonatomic, strong, nullable, readwrite) NSArray<MWKSearchResult *> *previews;

@property (nonatomic, strong) WMFArticlePreviewFetcher *previewFetcher;
@property (nonatomic, strong) WMFMostReadTitleFetcher *mostReadTitlesFetcher;

@end

@implementation WMFMostReadSectionController
@synthesize localDateDisplayString = _localDateDisplayString;
@synthesize localDateShortDisplayString = _localDateShortDisplayString;

- (instancetype)initWithDate:(NSDate *)date siteURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(url);
    NSParameterAssert(date);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.siteURL = url;
        self.date = date;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ site = %@, date = %@", [super description], self.siteURL, [self englishUTCDateString]];
}

#pragma mark - Accessors

- (void)setPreviews:(nullable NSArray<MWKSearchResult *> *)previews {
    _previews = [previews bk_select:^BOOL(MWKSearchResult *preview) {
        return [preview.titleNamespace wmf_isMainNamespace];
    }];
}

/**
 *  String to display to the user for the receiver's date.
 *
 *  "Most read" articles are computed for UTC dates. UTC time zone is used because converting to the user's time zone
 *  might accidentally change the "day" the app displays based on the the offset between UTC & the device's default time
 *  zone.  For example: 02/12/2016 01:26 UTC converted to EST is 02/11/2016 20:26, one day off!
 *
 *  @return A string formatted with the current locale, in the UTC time zone.
 */
- (NSString *)localDateDisplayString {
    if (!_localDateDisplayString) {
        _localDateDisplayString =
            [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date];
    }
    return _localDateDisplayString;
}

- (NSString *)localDateShortDisplayString {
    if (!_localDateShortDisplayString) {
        _localDateShortDisplayString =
            [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date];
    }
    return _localDateShortDisplayString;
}

/**
 *  Stable string for the receiver's date that doesn't vary by current calendar, locale, or time zone.
 *
 *  This is necessary to ensure that cached sections are retrievable when the locale, calendar, etc. changes.
 *
 *  @return An english-formatted string of the receiver's date in the UTC time zone.
 */
- (NSString *)englishUTCDateString {
    return [[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:self.date];
}

- (WMFMostReadTitleFetcher *)mostReadTitlesFetcher {
    if (!_mostReadTitlesFetcher) {
        _mostReadTitlesFetcher = [[WMFMostReadTitleFetcher alloc] init];
    }
    return _mostReadTitlesFetcher;
}

- (WMFArticlePreviewFetcher *)previewFetcher {
    if (!_previewFetcher) {
        _previewFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _previewFetcher;
}

#pragma mark - Analytics

- (NSString *)analyticsContentType {
    return @"Most Read";
}

#pragma mark - WMFExploreSectionController

#pragma mark Meta

- (NSString *)sectionIdentifier {
    return [NSString stringWithFormat:@"%@_%@", self.siteURL.host, [self englishUTCDateString]];
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticleListCollectionViewCell estimatedRowHeight];
}

#pragma mark Header

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"trending-mini"];
}

- (NSAttributedString *)headerTitle {
    // fall back to language code if it can't be localized
    NSString *language = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:self.siteURL.wmf_language];

    NSString *heading = nil;

    //crash protection if language is nil
    if (language) {
        heading =
            [MWLocalizedString(@"explore-most-read-heading", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                            withString:language];
    } else {
        heading = MWLocalizedString(@"explore-most-read-generic-heading", nil);
    }

    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor wmf_exploreSectionHeaderTitleColor]};
    return [[NSAttributedString alloc] initWithString:heading attributes:attributes];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc]
        initWithString:self.localDateDisplayString
            attributes:@{NSForegroundColorAttributeName : [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_blueTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_lightBlueTintColor];
}

#pragma mark Footer

- (NSString *)footerText {
    return
        [MWLocalizedString(@"explore-most-read-footer-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                withString:self.localDateShortDisplayString];
}

- (UIViewController *)moreViewController {
    return [[WMFMostReadListTableViewController alloc] initWithPreviews:self.previews
                                                            fromSiteURL:self.siteURL
                                                                forDate:self.date
                                                              dataStore:self.dataStore];
}

#pragma mark Detail

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[WMFArticleViewController alloc] initWithArticleURL:[self urlForItemAtIndexPath:indexPath]
                                                      dataStore:self.dataStore];
}

#pragma mark - TitleProviding

- (nullable NSURL *)urlForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.items.count) {
        return nil;
    }
    MWKSearchResult *result = (MWKSearchResult *)self.items[indexPath.row];
    if (![result isKindOfClass:[MWKSearchResult class]]) {
        return nil;
    }
    return [self.siteURL wmf_URLWithTitle:result.displayTitle];
}

#pragma mark - WMFBaseExploreSectionController Subclass

- (nullable NSString *)placeholderCellIdentifier {
    return [WMFMainPagePlaceholderCollectionViewCell identifier];
}

- (nullable UINib *)placeholderCellNib {
    return [WMFMainPagePlaceholderCollectionViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 5;
}

- (NSString *)cellIdentifier {
    return [WMFArticleListCollectionViewCell wmf_nibName];
}

- (UINib *)cellNib {
    return [WMFArticleListCollectionViewCell wmf_classNib];
}

- (void)configureCell:(WMFArticleListCollectionViewCell *)cell
             withItem:(MWKSearchResult *)item
          atIndexPath:(NSIndexPath *)indexPath {
    [cell setImageURL:item.thumbnailURL];
    [cell setTitleText:item.displayTitle];
    [cell setDescriptionText:item.wikidataDescription];
}

- (AnyPromise *)fetchData {
    @weakify(self);
    return [self.mostReadTitlesFetcher fetchMostReadTitlesForSiteURL:self.siteURL date:self.date]
        .then(^id(WMFMostReadTitlesResponseItem *mostReadResponse) {
            @strongify(self);
            NSParameterAssert([mostReadResponse.siteURL isEqual:self.siteURL]);
            if (!self) {
                return [NSError cancelledError];
            }
            self.mostReadArticlesResponse = mostReadResponse;
        WMF_TECH_DEBT_TODO(need to test for issues with really long query strings);
        NSArray<NSURL *> *titlesToPreview = [mostReadResponse.articles
            bk_map:^NSURL *(WMFMostReadTitlesResponseItemArticle *article) {
                // HAX: must normalize title otherwise it won't match fetched previews. this is why pageid > title
                return [self.siteURL wmf_URLWithTitle:article.titleText];
            }];
        return [self.previewFetcher
            fetchArticlePreviewResultsForArticleURLs:titlesToPreview
                                             siteURL:mostReadResponse.siteURL
                                       extractLength:0
                                      thumbnailWidth:[[UIScreen mainScreen] wmf_listThumbnailWidthForScale].unsignedIntegerValue];
        })
        .then(^NSArray<MWKSearchResult *> *(NSArray<MWKSearchResult *> *previews) {
            @strongify(self);

            // Now that we have preview data we can check for articleID. If articleID is zero
            // it's not a regular article. Rejecting these hides most special pages.
            previews = [previews bk_reject:^BOOL(MWKSearchResult *previews) {
                return (previews.articleID == 0);
            }];

            self.previews = previews;
            // only return first 5 previews to the section, store the rest internally for the full list view
            return [self.previews wmf_safeSubarrayWithRange:NSMakeRange(0, 5)];
        });
}

@end

NS_ASSUME_NONNULL_END

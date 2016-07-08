
#import "WMFRandomSectionController.h"
#import "WMFRandomArticleFetcher.h"

#import "MWKSite.h"
#import "MWKSavedPageList.h"
#import "MWKSearchResult.h"
#import "MWKDataStore.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "WMFArticlePlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"
#import "WMFSaveButtonController.h"
#import "WMFArticleBrowserViewController.h"
#import "WMFRandomArticleViewController.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) WMFRandomArticleFetcher* fetcher;

@property (nonatomic, strong, nullable) MWKSearchResult* result;

@property (nonatomic, weak, nullable) WMFArticlePreviewTableViewCell* cell;

@end

@implementation WMFRandomSectionController

- (instancetype)initWithSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.searchSite = site;
    }
    return self;
}

- (WMFRandomArticleFetcher*)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFRandomArticleFetcher alloc] init];
    }
    return _fetcher;
}

- (id)sectionIdentifier {
    return WMFRandomSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"random-mini"];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-random-article-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:MWSiteLocalizedString(self.searchSite, @"onboarding-wikipedia", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
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
    cell.saveButtonController.analyticsContext     = self;
    cell.saveButtonController.analyticsContentType = self;
    self.cell                                      = cell;
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticlePreviewTableViewCell estimatedRowHeight];
}

- (NSString*)analyticsContentType {
    return @"Random";
}

- (AnyPromise*)fetchData {
    [self.cell setLoading:YES];
    @weakify(self);
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.fetcher fetchRandomArticleWithSite:self.searchSite failure:^(NSError *error) {
            @strongify(self);
            self.result = nil;
            [self.cell setLoading:NO];
            resolve(error);
        } success:^(MWKSearchResult *result) {
            @strongify(self);
            if (!self) {
                resolve([NSError cancelledError]);
                return;
            }
            [self.cell setLoading:NO];
            self.result = result;
            resolve(@[result]);
        }];
    }];

}

- (UIViewController*)detailViewControllerForItemAtIndexPath:(NSIndexPath*)indexPath {
    MWKTitle* title = [self titleForItemAtIndexPath:indexPath];
    return [[WMFRandomArticleViewController alloc] initWithArticleTitle:title randomArticleFetcher:self.fetcher site:self.searchSite dataStore:self.dataStore];
}

- (void)didEndDisplayingSection {
    self.cell = nil;
}

#pragma mark Footer

- (NSString*)footerText {
    return MWLocalizedString(@"explore-random-more-footer", nil);
}

- (UIViewController*)moreViewController {
    return [[WMFRandomArticleViewController alloc] initWithArticleTitle:nil randomArticleFetcher:self.fetcher site:self.searchSite dataStore:self.dataStore];
}


#pragma mark - WMFTitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.searchSite titleWithString:self.result.displayTitle];
}

@end

NS_ASSUME_NONNULL_END


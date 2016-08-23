#import "WMFRandomSectionController.h"
#import "WMFRandomArticleFetcher.h"

#import "MWKSavedPageList.h"
#import "MWKSearchResult.h"
#import "MWKDataStore.h"

#import "WMFArticlePreviewCollectionViewCell.h"
#import "WMFArticlePlaceholderCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"
#import "WMFRandomArticleViewController.h"
#import "WMFFirstRandomViewController.h"
#import <Tweaks/FBTweakInline.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property (nonatomic, strong) WMFRandomArticleFetcher *fetcher;

@property (nonatomic, strong, nullable) MWKSearchResult *result;

@property (nonatomic, weak, nullable) WMFArticlePreviewCollectionViewCell *cell;

@property (nonatomic, readonly, getter=isNewInterfaceEnabled) BOOL newInterfaceEnabled;

@end

@implementation WMFRandomSectionController

- (instancetype)initWithSearchSiteURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore {
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.searchSiteURL = url;
    }
    return self;
}

- (WMFRandomArticleFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFRandomArticleFetcher alloc] init];
    }
    return _fetcher;
}

- (id)sectionIdentifier {
    return WMFRandomSectionIdentifier;
}

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"random-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-random-article-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:MWSiteLocalizedString(self.searchSiteURL, @"onboarding-wikipedia", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
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
    self.cell = cell;
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticlePreviewCollectionViewCell estimatedRowHeight];
}

- (NSString *)analyticsContentType {
    return @"Random";
}

- (AnyPromise *)fetchData {
    [self.cell setLoading:YES];
    @weakify(self);
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.fetcher fetchRandomArticleWithSiteURL:self.searchSiteURL
            failure:^(NSError *error) {
                @strongify(self);
                self.result = nil;
                [self.cell setLoading:NO];
                resolve(error);
            }
            success:^(MWKSearchResult *result) {
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

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self urlForItemAtIndexPath:indexPath];

    if (self.isNewInterfaceEnabled) {
        return [[WMFRandomArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
    } else {
        return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
    }
}

- (void)didEndDisplayingSection {
    self.cell = nil;
}

- (BOOL)prefersWiderColumn {
    return YES;
}

#pragma mark - Tweak

- (BOOL)isNewInterfaceEnabled {
    return FBTweakValue(@"Explore", @"Random", @"Show new interface", NO);
}

#pragma mark - WMFHeaderActionProviding

- (UIImage *)headerButtonIcon {
    return [UIImage imageNamed:@"refresh-mini"];
}

- (void)performHeaderButtonAction {
    [self fetchDataUserInitiated];
}

- (BOOL)isHeaderActionEnabled {
    return !self.isNewInterfaceEnabled;
}

#pragma mark - WMFMoreFooterProviding

- (NSString *)footerText {
    return MWLocalizedString(@"explore-another-random", nil);
}

- (UIViewController *)moreViewController {
    return [[WMFFirstRandomViewController alloc] initWithSiteURL:self.searchSiteURL dataStore:self.dataStore];
}

- (BOOL)isFooterEnabled {
    return self.isNewInterfaceEnabled;
}

#pragma mark - WMFTitleProviding

- (nullable NSURL *)urlForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.searchSiteURL wmf_URLWithTitle:self.result.displayTitle];
}

@end

NS_ASSUME_NONNULL_END

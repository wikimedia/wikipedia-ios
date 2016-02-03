
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

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) WMFRandomArticleFetcher* fetcher;

@property (nonatomic, strong, nullable) MWKSearchResult* result;

@property (nonatomic, weak) WMFArticlePreviewTableViewCell* cell;

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

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"main-menu-random", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_homeSectionHeaderTextColor]}];
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
    return @"Random";
}

- (AnyPromise*)fetchData {
    [self.cell setLoading:YES];
    @weakify(self);
    return [self.fetcher fetchRandomArticleWithSite:self.searchSite]
           .then(^(id result){
        @strongify(self);
        [self.cell setLoading:NO];
        self.result = result;
        return @[result];
    })
           .catch(^(NSError* error){
        @strongify(self);
        self.result = nil;
        [self.cell setLoading:NO];
        return error;
    });
}

- (UIViewController*)detailViewControllerForItemAtIndexPath:(NSIndexPath*)indexPath {
    MWKTitle* title              = [self titleForItemAtIndexPath:indexPath];
    UINavigationController* vc = [WMFArticleBrowserViewController embeddedBrowserViewControllerWithDataStore:[self dataStore] articleTitle:title restoreScrollPosition:NO source:self];
    return vc;
}

- (void)didEndDisplayingSection {
    self.cell = nil;
}

#pragma mark - WMFHeaderActionProviding

- (UIImage*)headerButtonIcon {
    return [UIImage imageNamed:@"refresh-mini"];
}

- (void)performHeaderButtonAction {
    [self fetchDataUserInitiated];
}

#pragma mark - WMFTitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.searchSite titleWithString:self.result.displayTitle];
}

@end

NS_ASSUME_NONNULL_END


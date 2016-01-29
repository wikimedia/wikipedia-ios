
#import "WMFRandomSectionController.h"
#import "WMFRandomArticleFetcher.h"

#import "MWKSite.h"
#import "MWKSavedPageList.h"
#import "MWKSearchResult.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "WMFArticlePlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"
#import "WMFSaveButtonController.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFRandomArticleFetcher* fetcher;

@property (nonatomic, strong, nullable) MWKSearchResult* result;

@property (nonatomic, weak) WMFArticlePreviewTableViewCell* cell;

@end

@implementation WMFRandomSectionController

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList {
    NSParameterAssert(site);
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.searchSite    = site;
        self.savedPageList = savedPageList;
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
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-random-article-sub-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
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

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodRandom;
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


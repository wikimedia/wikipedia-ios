
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


static NSString* const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFRandomArticleFetcher* fetcher;

@property (nonatomic, strong) MWKSearchResult* result;

@end

@implementation WMFRandomSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList {
    NSParameterAssert(site);
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.searchSite    = site;
        self.savedPageList = savedPageList;
        [self getNewRandomArticle];
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

- (UIImage*)headerButtonIcon {
    return [UIImage imageNamed:@"refresh-mini"];
}

- (void)performHeaderButtonAction {
    [self getNewRandomArticle];
}

- (NSArray*)items {
    if (self.result) {
        return @[self.result];
    } else {
        return @[@1];
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return [self.searchSite titleWithString:self.result.displayTitle];
}

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    [tableView registerNib:[WMFArticlePlaceholderTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePlaceholderTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if (self.result) {
        return [WMFArticlePreviewTableViewCell cellForTableView:tableView];
    } else {
        return [WMFArticlePlaceholderTableViewCell cellForTableView:tableView];
    }
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFArticlePreviewTableViewCell class]]) {
        WMFArticlePreviewTableViewCell* previewCell = (id)cell;
        previewCell.titleText       = self.result.displayTitle;
        previewCell.descriptionText = self.result.wikidataDescription;
        previewCell.snippetText     = self.result.extract;
        [previewCell setImageURL:self.result.thumbnailURL];
        [previewCell setSaveableTitle:[self titleForItemAtIndex:indexPath.row] savedPageList:self.savedPageList];
        previewCell.loading = self.fetcher.isFetching;
        [previewCell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
        previewCell.saveButtonController.analyticsSource = self;
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return self.result != nil;
}

- (void)getNewRandomArticle {
    if (self.fetcher.isFetching) {
        return;
    }

    @weakify(self);
    [self.fetcher fetchRandomArticleWithSite:self.searchSite]
    .then(^(id result){
        @strongify(self);
        self.result = result;
        [self.delegate controller:self didUpdateItemsAtIndexes:[NSIndexSet indexSetWithIndex:0]];
    })
    .catch(^(NSError* error){
        @strongify(self);
        [self.delegate controller:self didFailToUpdateWithError:error];
    });

    // call after fetch starts so loading indicator displays
    [self.delegate controller:self didUpdateItemsAtIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (NSString*)analyticsName {
    return @"Random";
}

@end

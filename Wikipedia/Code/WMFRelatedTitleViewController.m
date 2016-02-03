
#import "WMFRelatedTitleViewController.h"
#import "MWKTitle.h"
#import "MWKSearchResult.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"
#import "WMFSaveButtonController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleViewController ()

@end

@implementation WMFRelatedTitleViewController

@dynamic dataSource;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
}

- (void)setDataSource:(WMFRelatedTitleListDataSource*)dataSource {
    self.title = [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:dataSource.title.text];

    dataSource.cellClass = [WMFArticlePreviewTableViewCell class];

    @weakify(self);
    dataSource.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell* cell,
                                      MWKSearchResult* searchResult,
                                      UITableView* tableView,
                                      NSIndexPath* indexPath) {
        @strongify(self);
        MWKTitle* title = [self.dataSource.title.site titleWithString:searchResult.displayTitle];
        [cell setSaveableTitle:title savedPageList:self.dataSource.savedPageList];
        cell.titleText       = searchResult.displayTitle;
        cell.descriptionText = searchResult.wikidataDescription;
        cell.snippetText     = searchResult.extract;
        [cell setImageURL:searchResult.thumbnailURL];
        [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
        cell.saveButtonController.analyticsSource = self;
    };

    [super setDataSource:dataSource];
}

- (NSString*)analyticsName {
    return @"Related";
}

@end

NS_ASSUME_NONNULL_END

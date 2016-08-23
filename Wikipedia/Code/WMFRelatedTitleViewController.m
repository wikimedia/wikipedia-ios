#import "WMFRelatedTitleViewController.h"
#import "MWKSearchResult.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleViewController ()

@end

@implementation WMFRelatedTitleViewController

@dynamic dataSource;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    self.tableView.estimatedRowHeight = [WMFArticlePreviewTableViewCell estimatedRowHeight];
}

- (void)setDataSource:(WMFRelatedTitleListDataSource *)dataSource {
    self.title = [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:dataSource.url.wmf_title];

    dataSource.cellClass = [WMFArticlePreviewTableViewCell class];

    @weakify(self);
    dataSource.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell *cell,
                                      MWKSearchResult *searchResult,
                                      UITableView *tableView,
                                      NSIndexPath *indexPath) {
        @strongify(self);
        NSURL *articleURL = [self.dataSource.url wmf_URLWithTitle:searchResult.displayTitle];
        [cell setSaveableURL:articleURL savedPageList:self.dataSource.savedPageList];
        cell.titleText = searchResult.displayTitle;
        cell.descriptionText = searchResult.wikidataDescription;
        cell.snippetText = searchResult.extract;
        [cell setImageURL:searchResult.thumbnailURL];
        cell.saveButtonController.analyticsContext = self;
    };

    [super setDataSource:dataSource];
}

- (NSString *)analyticsContext {
    return @"More Reccomended";
}

@end

NS_ASSUME_NONNULL_END

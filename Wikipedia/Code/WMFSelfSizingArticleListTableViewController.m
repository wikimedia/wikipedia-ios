
#import "WMFSelfSizingArticleListTableViewController.h"
#import "WMFIntrinsicSizeTableView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSelfSizingArticleListTableViewController ()

@end

@implementation WMFSelfSizingArticleListTableViewController

- (void)loadView {
    [super loadView];
    UITableView* tv = [[WMFIntrinsicSizeTableView alloc] initWithFrame:CGRectZero];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.delegate                                  = self;
    self.tableView                               = tv;
}

@end

NS_ASSUME_NONNULL_END
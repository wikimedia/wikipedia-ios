#import "WMFPageIssuesViewController.h"
#import <SSDataSources/SSDataSources.h>
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@implementation WMFPageIssuesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title                        = MWLocalizedString(@"page-issues", nil);
    self.tableView.estimatedRowHeight = 90.0;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell* cell, NSString* text, UITableView* tableView, NSIndexPath* indexPath) {
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.text          = text;
        [cell wmf_makeCellDividerBeEdgeToEdge];
        cell.userInteractionEnabled = NO;
    };

    self.dataSource.tableActionBlock = ^BOOL (SSCellActionType action, UITableView* tableView, NSIndexPath* indexPath) {
        return NO;
    };

    self.dataSource.tableView = self.tableView;

    @weakify(self);
    UIBarButtonItem* xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self.presentingViewController dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItem = xButton;
}

@end

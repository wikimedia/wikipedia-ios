#import "WMFPageIssuesViewController.h"
#import "SSDataSources.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

@implementation WMFPageIssuesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WMFLocalizedStringWithDefaultValue(@"page-issues", nil, nil, @"Page issues", @"Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).\n{{Identical|Page issue}}");
    self.tableView.estimatedRowHeight = 90.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, NSString *text, UITableView *tableView, NSIndexPath *indexPath) {
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.text = text;
        [cell wmf_makeCellDividerBeEdgeToEdge];
        cell.userInteractionEnabled = NO;
    };

    self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
        return NO;
    };

    self.dataSource.tableView = self.tableView;

    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.leftBarButtonItem = xButton;
}

- (void)closeButtonPressed {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

#import "WMFPageIssuesViewController.h"
#import "SSDataSources.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <WMF/EXTScope.h>
@import WMF.WMFLocalization;

@interface WMFPageIssuesViewController ()
@property (nonatomic, strong) WMFTheme *theme;
@end

@implementation WMFPageIssuesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }
    self.title = WMFLocalizedStringWithDefaultValue(@"page-issues", nil, nil, @"Page issues", @"Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).\n{{Identical|Page issue}}");
    self.tableView.estimatedRowHeight = 90.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    @weakify(self);
    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, NSString *text, UITableView *tableView, NSIndexPath *indexPath) {
        @strongify(self);
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.text = text;
        cell.userInteractionEnabled = NO;
        cell.backgroundView.backgroundColor = self.theme.colors.paperBackground;
        cell.selectedBackgroundView.backgroundColor = self.theme.colors.midBackground;
        cell.textLabel.textColor = self.theme.colors.primaryText;
    };

    self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
        return NO;
    };

    self.dataSource.tableView = self.tableView;

    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.leftBarButtonItem = xButton;

    [self applyTheme:self.theme];
}

- (void)closeButtonPressed {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.tableView.backgroundColor = theme.colors.baseBackground;
    [self.tableView reloadData];
}

@end

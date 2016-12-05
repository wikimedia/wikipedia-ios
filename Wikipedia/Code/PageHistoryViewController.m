#import "PageHistoryViewController.h"
#import "PageHistoryResultCell.h"
#import "WikipediaAppUtils.h"
#import "WikiGlyph_Chars.h"
#import "Defines.h"
#import "PaddedLabel.h"
#import "UITableView+DynamicCellHeight.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "Wikipedia-Swift.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFPageHistoryRevision.h"

#define TABLE_CELL_ID @"PageHistoryResultCell"

@interface PageHistoryViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) __block NSMutableArray<PageHistorySection *> *pageHistoryDataArray;
@property (strong, nonatomic) PageHistoryResultCell *offScreenSizingCell;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) PageHistoryFetcher *pageHistoryFetcher;
@property (assign, nonatomic) BOOL isLoadingData;
@property (assign, nonatomic) BOOL batchComplete;
@property (strong, nonatomic) PageHistoryRequestParameters *historyFetcherParams;

@end

@implementation PageHistoryViewController

- (NSString *)title {
    return MWLocalizedString(@"page-history-title", nil);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self getPageHistoryData];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.historyFetcherParams = [[PageHistoryRequestParameters alloc] initWithTitle:self.article.url.wmf_title];
    self.pageHistoryFetcher = [PageHistoryFetcher new];
    @weakify(self)
        UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX
                                                           handler:^(id sender) {
                                                               @strongify(self)
                                                                   [self dismissViewControllerAnimated:YES
                                                                                            completion:nil];
                                                           }];
    self.navigationItem.leftBarButtonItem = xButton;

    self.pageHistoryDataArray = @[].mutableCopy;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0 * MENUS_SCALE_MULTIPLIER, 10.0 * MENUS_SCALE_MULTIPLIER)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];

    [self.tableView registerNib:[UINib nibWithNibName:@"PageHistoryResultPrototypeView" bundle:nil]
         forCellReuseIdentifier:TABLE_CELL_ID];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (PageHistoryResultCell *)[self.tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)getPageHistoryData {
    self.isLoadingData = YES;

    @weakify(self);
    [self.pageHistoryFetcher fetchRevisionInfo:self.article.url requestParams:self.historyFetcherParams].then(^(HistoryFetchResults *historyFetchResults) {
                                                                                                            @strongify(self);
                                                                                                            [self.pageHistoryDataArray addObjectsFromArray:historyFetchResults.items];
                                                                                                            self.historyFetcherParams = [historyFetchResults getPageHistoryRequestParameters:self.article.url];
                                                                                                            self.batchComplete = historyFetchResults.batchComplete;
                                                                                                            [[WMFAlertManager sharedInstance] dismissAlert];
                                                                                                            [self.tableView reloadData];
                                                                                                        })
        .catch(^(NSError *error) {
            @strongify(self);
            DDLogError(@"Failed to fetch items for section %@. %@", self, error);
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:NO tapCallBack:NULL];
        })
        .finally(^{
            @strongify(self);
            self.isLoadingData = NO;
        });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.pageHistoryDataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PageHistorySection *sectionItems = self.pageHistoryDataArray[section];
    return sectionItems.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = TABLE_CELL_ID;
    PageHistoryResultCell *cell = (PageHistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];

    [self updateViewsInCell:cell forIndexPath:indexPath];

    return cell;
}

- (void)updateViewsInCell:(PageHistoryResultCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    PageHistorySection *section = self.pageHistoryDataArray[indexPath.section];
    WMFPageHistoryRevision *row = section.items[indexPath.row];

    [cell setName:row.user
             date:row.revisionDate
            delta:@(row.revisionSize)
             icon:row.authorIcon
          summary:row.parsedComment
        separator:(section.items.count > 1)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Update the sizing cell with any data which could change the cell height.
    [self updateViewsInCell:self.offScreenSizingCell forIndexPath:indexPath];

    // Determine height for the current configuration of the sizing cell.
    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = CHROME_COLOR;
    view.autoresizesSubviews = YES;
    PaddedLabel *label = [[PaddedLabel alloc] init];

    CGFloat leadingIndent = 10.0 * MENUS_SCALE_MULTIPLIER;
    label.padding = UIEdgeInsetsMake(0, leadingIndent, 0, 0);

    label.font = [UIFont boldSystemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
    label.textColor = [UIColor darkGrayColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor = [UIColor clearColor];

    label.textAlignment = NSTextAlignmentNatural;

    label.text = self.pageHistoryDataArray[section].sectionTitle;

    [view addSubview:label];

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 27.0 * MENUS_SCALE_MULTIPLIER;
}

- (BOOL)shouldLoadNewData {
    if (self.batchComplete || self.isLoadingData) {
        return NO;
    }
    CGFloat maxY = self.tableView.contentOffset.y + self.tableView.frame.size.height + 200.0;
    BOOL shouldLoad = NO;
    if (maxY >= self.tableView.contentSize.height) {
        shouldLoad = YES;
    }
    return shouldLoad;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self shouldLoadNewData]) {
        [self getPageHistoryData];
    }
}

@end

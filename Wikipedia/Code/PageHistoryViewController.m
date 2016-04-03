//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryViewController.h"
#import "PageHistoryResultCell.h"
#import "WikipediaAppUtils.h"
#import "QueuesSingleton.h"
#import "NSDate+Utilities.h"
#import "WikiGlyph_Chars.h"
#import "Defines.h"
#import "PaddedLabel.h"
#import "UITableView+DynamicCellHeight.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "PageHistoryFetcher.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFRevision.h"


#define TABLE_CELL_ID @"PageHistoryResultCell"

@interface PageHistoryViewController () <FetchFinishedDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) __block NSMutableArray* pageHistoryDataArray;
@property (strong, nonatomic) PageHistoryResultCell* offScreenSizingCell;
@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (assign, nonatomic) BOOL loadInProgress;

@end

@implementation PageHistoryViewController

- (NSString*)title {
    return MWLocalizedString(@"page-history-title", nil);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self getPageHistoryData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[QueuesSingleton sharedInstance].pageHistoryFetchManager wmf_cancelAllTasks];

    [super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItem = xButton;

    self.pageHistoryDataArray = @[].mutableCopy;

    self.tableView.tableFooterView                 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0 * MENUS_SCALE_MULTIPLIER, 10.0 * MENUS_SCALE_MULTIPLIER)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];

    [self.tableView registerNib:[UINib nibWithNibName:@"PageHistoryResultPrototypeView" bundle:nil]
         forCellReuseIdentifier:TABLE_CELL_ID];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (PageHistoryResultCell*)[self.tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error;
{
    self.loadInProgress = NO;
    if ([sender isKindOfClass:[PageHistoryFetcher class]]) {
        NSMutableArray* pageHistoryDataArray = (NSMutableArray*)fetchedData;
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:

                self.pageHistoryDataArray = pageHistoryDataArray;
                [[WMFAlertManager sharedInstance] dismissAlert];
                [self.tableView reloadData];

                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [[WMFAlertManager sharedInstance] dismissAlert];

                break;
            case FETCH_FINAL_STATUS_FAILED:
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:NO tapCallBack:NULL];
                break;
        }
    }
}

- (void)getPageHistoryData {
    self.loadInProgress = YES;
    (void)[[PageHistoryFetcher alloc] initAndFetchHistoryForTitle:self.article.title
                                                      withManager:[QueuesSingleton sharedInstance].pageHistoryFetchManager
                                               thenNotifyDelegate:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return self.pageHistoryDataArray.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* sectionItems = self.pageHistoryDataArray[section];
    return sectionItems.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* cellID     = TABLE_CELL_ID;
    PageHistoryResultCell* cell = (PageHistoryResultCell*)[tableView dequeueReusableCellWithIdentifier:cellID];

    [self updateViewsInCell:cell forIndexPath:indexPath];

    return cell;
}

- (void)updateViewsInCell:(PageHistoryResultCell*)cell forIndexPath:(NSIndexPath*)indexPath {
    NSArray* section = self.pageHistoryDataArray[indexPath.section];
    WMFRevision* row = section[indexPath.row];

    [cell setName:row.user
             time:@"he"
            delta:@(row.revisionSize)
             icon:row.authorIcon
          summary:row.parsedComment
        separator:(section.count > 1)];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    // Update the sizing cell with any data which could change the cell height.
    [self updateViewsInCell:self.offScreenSizingCell forIndexPath:indexPath];

    // Determine height for the current configuration of the sizing cell.
    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
//    NSDictionary* sectionDict = self.pageHistoryDataArray[indexPath.section];
//    NSArray* rows             = sectionDict[@"revisions"];
//    NSDictionary* row         = rows[indexPath.row];
//    NSLog(@"row = %@", row);

// TODO: row contains a revisionid, make tap cause diff for that revision to open in Safari?
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor     = CHROME_COLOR;
    view.autoresizesSubviews = YES;
    PaddedLabel* label = [[PaddedLabel alloc] init];

    CGFloat leadingIndent = 10.0 * MENUS_SCALE_MULTIPLIER;
    label.padding = UIEdgeInsetsMake(0, leadingIndent, 0, 0);

    label.font             = [UIFont boldSystemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
    label.textColor        = [UIColor darkGrayColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor  = [UIColor clearColor];

    label.textAlignment = NSTextAlignmentNatural;

    //NSDictionary* sectionDict = self.pageHistoryDataArray[section];

    NSNumber* daysAgo = @(1);//sectionDict[@"daysAgo"];
    NSDate* date      = [NSDate dateWithDaysBeforeNow:daysAgo.integerValue];
    label.text = [[NSDateFormatter wmf_longDateFormatter] stringFromDate:date];

    [view addSubview:label];

    return view;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 27.0 * MENUS_SCALE_MULTIPLIER;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldLoadNewData {
    
    CGFloat maxY = self.tableView.contentOffset.y + self.tableView.frame.size.height;
    BOOL shouldLoad = NO;
    if (!self.loadInProgress && maxY >= self.tableView.contentSize.height) {
        shouldLoad = YES;// allItemsLoaded]?;
    }
    return shouldLoad;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    
    // If we scroll to the end of the view new data should be loaded.
    if ([self shouldLoadNewData]) {
        [self getPageHistoryData];
    }
}

@end

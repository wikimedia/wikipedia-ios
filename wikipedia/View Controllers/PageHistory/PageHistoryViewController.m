//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryViewController.h"
#import "PageHistoryResultCell.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "UIViewController+Alert.h"
#import "NSDate-Utilities.h"
#import "WikiGlyph_Chars.h"
#import "UIViewController+ModalPop.h"
#import "Defines.h"
#import "PaddedLabel.h"
#import "UITableView+DynamicCellHeight.h"

#define TABLE_CELL_ID @"PageHistoryResultCell"

@interface PageHistoryViewController ()

@property (strong, nonatomic) __block NSMutableArray *pageHistoryDataArray;
@property (strong, nonatomic) PageHistoryResultCell *offScreenSizingCell;

@end

@implementation PageHistoryViewController

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_X_WITH_LABEL;
}

-(NSString *)title
{
    return MWLocalizedString(@"page-history-title", nil);
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self getPageHistoryData];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[QueuesSingleton sharedInstance].pageHistoryFetchManager.operationQueue cancelAllOperations];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self popModal];
            
            break;
        default:
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.hidesBackButton = YES;

    self.pageHistoryDataArray = @[].mutableCopy;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0 * MENUS_SCALE_MULTIPLIER, 10.0 * MENUS_SCALE_MULTIPLIER)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerNib:[UINib nibWithNibName: @"PageHistoryResultPrototypeView" bundle: nil]
         forCellReuseIdentifier: TABLE_CELL_ID];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (PageHistoryResultCell *)[self.tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error;
{
    if ([sender isKindOfClass:[PageHistoryFetcher class]]) {
        NSMutableArray *pageHistoryDataArray = (NSMutableArray *)fetchedData;
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:

                self.pageHistoryDataArray = pageHistoryDataArray;
                [self fadeAlert];
                [self.tableView reloadData];
            
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];

            break;
            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
            break;

        }
    }
}

-(void)getPageHistoryData
{
    (void)[[PageHistoryFetcher alloc] initAndFetchHistoryForTitle: [SessionSingleton sharedInstance].title
                                                      withManager: [QueuesSingleton sharedInstance].pageHistoryFetchManager
                                               thenNotifyDelegate: self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.pageHistoryDataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionDict = self.pageHistoryDataArray[section];
    NSArray *rows = sectionDict[@"revisions"];
    return rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = TABLE_CELL_ID;
    PageHistoryResultCell *cell = (PageHistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];

    [self updateViewsInCell:cell forIndexPath:indexPath];
    
    return cell;
}

-(void)updateViewsInCell:(PageHistoryResultCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionDict = self.pageHistoryDataArray[indexPath.section];
    NSArray *rows = sectionDict[@"revisions"];
    NSDictionary *row = rows[indexPath.row];
    
    [cell setName: row[@"user"]
             time: row[@"timestamp"]
            delta: row[@"characterDelta"]
             icon: row[@"anon"] ? WIKIGLYPH_USER_SLEEP : WIKIGLYPH_USER_SMILE
          summary: row[@"parsedcomment"]
        separator: (rows.count > 1)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the sizing cell with any data which could change the cell height.
    [self updateViewsInCell:self.offScreenSizingCell forIndexPath:indexPath];

    // Determine height for the current configuration of the sizing cell.
    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionDict = self.pageHistoryDataArray[indexPath.section];
    NSArray *rows = sectionDict[@"revisions"];
    NSDictionary *row = rows[indexPath.row];
    NSLog(@"row = %@", row);
    
// TODO: row contains a revisionid, make tap cause diff for that revision to open in Safari?

}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
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
    
    label.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    
    NSDictionary *sectionDict = self.pageHistoryDataArray[section];
    
    NSNumber *daysAgo = sectionDict[@"daysAgo"];
    NSDate *date = [NSDate dateWithDaysBeforeNow:daysAgo.integerValue];
    
    NSString *formattedDate = [NSDateFormatter localizedStringFromDate: date
                                                             dateStyle: NSDateFormatterLongStyle
                                                             timeStyle: NSDateFormatterNoStyle];
    
    label.text = formattedDate;
    
    [view addSubview:label];
    
    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 27.0 * MENUS_SCALE_MULTIPLIER;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

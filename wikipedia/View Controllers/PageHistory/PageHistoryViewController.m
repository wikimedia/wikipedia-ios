//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryViewController.h"
#import "PageHistoryResultCell.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "CenterNavController.h"
#import "UIViewController+Alert.h"
#import "NSDate-Utilities.h"
#import "NSString+Extras.h"
#import "WikiGlyph_Chars.h"
#import "RootViewController.h"
#import "UIViewController+ModalPop.h"
#import "Defines.h"
#import "PaddedLabel.h"
#import "FetcherBase.h"

@interface PageHistoryViewController (){

}

@property (strong, nonatomic) __block NSMutableArray *pageHistoryDataArray;

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
         forCellReuseIdentifier: @"PageHistoryResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)fetchFinished: (id)sender
             userData: (id)userData
               status: (FetchFinalStatus)status
                error: (NSError *)error;
{
    if ([sender isKindOfClass:[PageHistoryFetcher class]]) {
        NSMutableArray *pageHistoryDataArray = (NSMutableArray *)userData;
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
    (void)[[PageHistoryFetcher alloc] initAndFetchHistoryForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                           domain: [SessionSingleton sharedInstance].currentArticleDomain
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
    static NSString *cellID = @"PageHistoryResultCell";
    PageHistoryResultCell *cell = (PageHistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *sectionDict = self.pageHistoryDataArray[indexPath.section];
    NSArray *rows = sectionDict[@"revisions"];
    NSDictionary *row = rows[indexPath.row];
    
    cell.separatorHeightConstraint.constant =
        (rows.count == 1) ? 0.0f : (1.0f / [UIScreen mainScreen].scale);

    NSDate *timeStamp = [row[@"timestamp"] getDateFromIso8601DateString];
    
    NSString *formattedTime =
        [NSDateFormatter localizedStringFromDate: timeStamp
                                       dateStyle: NSDateFormatterNoStyle
                                       timeStyle: NSDateFormatterShortStyle];
    
    NSString *commentNoHTML = [row[@"parsedcomment"] getStringWithoutHTML];

    NSNumber *delta = row[@"characterDelta"];
    
    cell.summaryLabel.text = commentNoHTML;
    cell.timeLabel.text = formattedTime;

    cell.deltaLabel.text =
        [NSString stringWithFormat:@"%@%@", (delta.integerValue > 0) ? @"+" : @"", delta.stringValue];
    
    cell.deltaLabel.textColor =
        (delta.integerValue > 0)
        ?
        [UIColor colorWithRed:0.00 green:0.69 blue:0.49 alpha:1.0]
        :
        [UIColor colorWithRed:0.95 green:0.00 blue:0.00 alpha:1.0]
        ;

    cell.iconLabel.attributedText =
    [[NSAttributedString alloc] initWithString: row[@"anon"] ? WIKIGLYPH_USER_SLEEP : WIKIGLYPH_USER_SMILE
                                    attributes: @{
                                                  NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:23.0 * MENUS_SCALE_MULTIPLIER],
                                                  NSForegroundColorAttributeName : [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0],
                                                  NSBaselineOffsetAttributeName: @1
                                                  }];
    
    cell.nameLabel.text = row[@"user"];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Getting dynamic cell height which respects auto layout constraints is tricky.

    // First get the cell configured exactly as it is for display.
    PageHistoryResultCell *cell =
        (PageHistoryResultCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];

    // Then coax the cell into taking on the size that would satisfy its layout constraints (and
    // return that size's height).
    // From: http://stackoverflow.com/a/18746930/135557
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    cell.bounds = CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, cell.bounds.size.height);
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    return ([cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0f);
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

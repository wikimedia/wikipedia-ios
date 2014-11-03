//  Created by Monte Hurd on 5/22/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PrimaryMenuViewController.h"
#import "PrimaryMenuTableViewCell.h"
#import "WikipediaAppUtils.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "SessionSingleton.h"
#import "LoginViewController.h"
#import "UIViewController+Alert.h"
#import "Defines.h"
#import "UIViewController+ModalPresent.h"
#import "UIViewController+ModalPop.h"
#import "NSObject+ConstraintsScale.h"
#import "UITableView+DynamicCellHeight.h"
#import "UIScreen+Extras.h"

#define TABLE_CELL_ID @"PrimaryMenuCell"

typedef NS_ENUM(NSInteger, PrimaryMenuItemTag) {
    PRIMARY_MENU_ITEM_UNKNOWN,
    PRIMARY_MENU_ITEM_LOGIN,
    PRIMARY_MENU_ITEM_RANDOM,
    PRIMARY_MENU_ITEM_RECENT,
    PRIMARY_MENU_ITEM_SAVEDPAGES,
    PRIMARY_MENU_ITEM_MORE,
    PRIMARY_MENU_ITEM_TODAY,
    PRIMARY_MENU_ITEM_NEARBY
};

@interface PrimaryMenuViewController ()

@property (weak, nonatomic) IBOutlet PaddedLabel *moreButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *tableData;

@property (strong, nonatomic) PrimaryMenuTableViewCell *offScreenSizingCell;

@end

@implementation PrimaryMenuViewController

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_X_WITH_LABEL;
}

-(NavBarStyle)navBarStyle
{
    return NAVBAR_STYLE_NIGHT;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //[self setupTableData];
    //[self randomizeTitles];

    self.moreButton.text = MWLocalizedString(@"main-menu-more", nil);
    if ([[SessionSingleton sharedInstance].site.language isEqualToString:@"en"]) {
        self.moreButton.text = [self.moreButton.text uppercaseString];
    }
    self.moreButton.accessibilityLabel = MWLocalizedString(@"menu-more-accessibility-label", nil);
    self.moreButton.padding = UIEdgeInsetsMake(7, 17, 7, 17);
    self.moreButton.font = [UIFont systemFontOfSize:16.0 * MENUS_SCALE_MULTIPLIER];
    
    self.moreButton.userInteractionEnabled = YES;
    [self.moreButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreButtonTapped:)]];

    [self adjustConstraintsScaleForViews:@[self.tableView, self.moreButton, self.moreButton.superview]];
    
    [self addTableHeaderView];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (PrimaryMenuTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
}

-(void)addTableHeaderView
{
    CGFloat topPadding = [[UIScreen mainScreen] isThreePointFiveInchScreen] ? 5 : 38;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, topPadding)];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupTableData];
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_LABEL:
            [self popModal];

            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupTableData
{
    self.tableData = @[].mutableCopy;

    NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if(!userName){
        [self.tableData addObject:@{
            @"title": MWLocalizedString(@"main-menu-account-login", nil),
            @"tag": @(PRIMARY_MENU_ITEM_LOGIN)
        }];
    }

    [self.tableData addObjectsFromArray: @[
        @{
            @"title": MWLocalizedString(@"main-menu-show-today", nil),
            @"tag": @(PRIMARY_MENU_ITEM_TODAY)
        },
        @{
            @"title": MWLocalizedString(@"main-menu-random", nil),
            @"tag": @(PRIMARY_MENU_ITEM_RANDOM)
        },
        @{
            @"title": MWLocalizedString(@"main-menu-nearby", nil),
            @"tag": @(PRIMARY_MENU_ITEM_NEARBY)
        },
        @{
            @"title": MWLocalizedString(@"main-menu-show-history", nil),
            @"tag": @(PRIMARY_MENU_ITEM_RECENT)
        },
        @{
            @"title": MWLocalizedString(@"main-menu-show-saved", nil),
            @"tag": @(PRIMARY_MENU_ITEM_SAVEDPAGES)
        }
    ]];
}

/*
-(void)randomizeTitles
{
    for (NSMutableDictionary *rowData in self.tableData) {
        rowData[@"title"] = [@"abc " randomlyRepeatMaxTimes:50];
    }
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = TABLE_CELL_ID;

    PrimaryMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

    [self updateViewsInCell:cell forIndexPath:indexPath];
    
    return cell;
}

-(void)updateViewsInCell:(PrimaryMenuTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.label.text = rowData[@"title"];

    // Set "tag" so if this item is tapped we can have a pointer to the label
    // which is presently onscreen in this cell so it can be animated. Note:
    // this is needed because table cells get reused.
    NSNumber *tagNumber = rowData[@"tag"];
    cell.label.tag = tagNumber.integerValue;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the sizing cell with any data which could change the cell height.
    [self updateViewsInCell:self.offScreenSizingCell forIndexPath:indexPath];

    // Determine height for the current configuration of the sizing cell.
    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PrimaryMenuTableViewCell *cell =
        (PrimaryMenuTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    NSDictionary *selectedRowDict = self.tableData[indexPath.row];
    NSNumber *tagNumber = selectedRowDict[@"tag"];

    [self animateView:cell thenPerformActionForItem:tagNumber.integerValue];
}

-(void)moreButtonTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self animateView:self.moreButton thenPerformActionForItem:PRIMARY_MENU_ITEM_MORE];
    }
}

-(void)animateView:(UIView *)view thenPerformActionForItem:(PrimaryMenuItemTag)tag
{
    [view animateAndRewindXF: CATransform3DMakeScale(1.03f, 1.03f, 1.04f)
                  afterDelay: 0.0
                    duration: 0.1
                        then: ^{
                            [self performActionForItem:tag];
                        }];
}

-(void)performActionForItem:(PrimaryMenuItemTag)tag
{
    switch (tag) {
        case PRIMARY_MENU_ITEM_LOGIN: {
            [self performModalSequeWithID: @"modal_segue_show_login"
                          transitionStyle: UIModalTransitionStyleCoverVertical
                                    block: ^(LoginViewController *loginVC){
                                        loginVC.funnel = [[LoginFunnel alloc] init];
                                        [loginVC.funnel logStartFromNavigation];
                                    }];
        }
            break;
        case PRIMARY_MENU_ITEM_RANDOM: {
            //[self showAlert:MWLocalizedString(@"fetching-random-article", nil) type:ALERT_TYPE_TOP duration:-1];
            [NAV loadRandomArticle];
            [self popModal];
        }
            break;
        case PRIMARY_MENU_ITEM_TODAY: {
            //[self showAlert:MWLocalizedString(@"fetching-today-article", nil) type:ALERT_TYPE_TOP duration:-1];
            [NAV loadTodaysArticle];
            [self popModal];
        }
            break;
        case PRIMARY_MENU_ITEM_RECENT:
            [self performModalSequeWithID: @"modal_segue_show_history"
                          transitionStyle: UIModalTransitionStyleCoverVertical
                                    block: nil];
            break;
        case PRIMARY_MENU_ITEM_SAVEDPAGES:
            [self performModalSequeWithID: @"modal_segue_show_saved_pages"
                          transitionStyle: UIModalTransitionStyleCoverVertical
                                    block: nil];
            break;
        case PRIMARY_MENU_ITEM_NEARBY:
            [self performModalSequeWithID: @"modal_segue_show_nearby"
                          transitionStyle: UIModalTransitionStyleCoverVertical
                                    block: nil];
            break;
        case PRIMARY_MENU_ITEM_MORE:
            [self performModalSequeWithID: @"modal_segue_show_secondary_menu"
                          transitionStyle: UIModalTransitionStyleCoverVertical
                                    block: nil];
            break;
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

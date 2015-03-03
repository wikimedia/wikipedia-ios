#import "WMFDebugViewController.h"
#import "WikipediaAppUtils.h"
#import "TopMenuViewController.h"
#import "UIViewController+ModalPop.h"

@implementation WMFDebugViewController

- (instancetype)initWithFeatures:(NSArray *)features
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _features = features;
    }
    return self;
}

- (NavBarMode)navBarMode
{
    return NAVBAR_MODE_X_WITH_LABEL;
}

- (NSString*)title
{
    return MWLocalizedString(@"main-menu-debug", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navItemTappedNotification:)
                                                 name:@"NavItemTapped"
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"NavItemTapped"
                                                  object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.features enumerateObjectsUsingBlock:^(id<WMFDebugFeature> feature, NSUInteger idx, BOOL *stop) {
        [[feature debugViewDelegate] applyCellConfigurationToTable:self.tableView];
    }];
}

- (void)navItemTappedNotification:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    UIView* tappedItem     = userInfo[@"tappedItem"];
    
    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self popModal];
            break;
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.features.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.features[section] debugViewDataSource] numberOfRows];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.features[section] debugViewDataSource] headerTitle];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.features[indexPath.section] debugViewDataSource] tableView:tableView
                                                       cellForRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[self.features[indexPath.section] debugViewDelegate] didSelectRow:indexPath.row];
}

@end

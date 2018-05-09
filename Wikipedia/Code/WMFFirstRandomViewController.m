#import "WMFFirstRandomViewController.h"
#import <WMF/WMFRandomArticleFetcher.h>
#import "Wikipedia-Swift.h"
#import <WMF/MWKDataStore.h>
#import <WMF/SessionSingleton.h>
#import <WMF/MWKSearchResult.h>
#import "WMFRandomArticleViewController.h"
#import "UIViewController+WMFArticlePresentation.h"

@interface WMFFirstRandomViewController ()

@end

@implementation WMFFirstRandomViewController

- (nonnull instancetype)initWithSiteURL:(nonnull NSURL *)siteURL dataStore:(nonnull MWKDataStore *)dataStore theme:(WMFTheme *)theme {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.siteURL = siteURL;
        self.dataStore = dataStore;
        self.hidesBottomBarWhenPushed = YES;
        self.theme = theme;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.siteURL);
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSURL *siteURL = self.siteURL;
    WMFRandomArticleFetcher *fetcher = [[WMFRandomArticleFetcher alloc] init];
    [fetcher fetchRandomArticleWithSiteURL:siteURL
        failure:^(NSError *error) {
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
        }
        success:^(MWKSearchResult *result) {
            NSURL *titleURL = [result articleURLForSiteURL:siteURL];
            WMFRandomArticleViewController *randomArticleVC = [[WMFRandomArticleViewController alloc] initWithArticleURL:titleURL dataStore:self.dataStore theme:self.theme];
#if WMF_TWEAKS_ENABLED
            randomArticleVC.permaRandomMode = NO; // self.isPermaRandomMode to turn on
#endif
            NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
            [viewControllers replaceObjectAtIndex:viewControllers.count - 1 withObject:randomArticleVC];
            [self.navigationController setViewControllers:viewControllers];
        }];
}

- (void)applyTheme:(WMFTheme *)theme {
    self.view.backgroundColor = theme.colors.paperBackground;
}

@end

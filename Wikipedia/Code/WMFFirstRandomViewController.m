#import "WMFFirstRandomViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "Wikipedia-Swift.h"
#import "MWKDataStore.h"
#import "WMFArticleDataStore.h"
#import "SessionSingleton.h"
#import "MWKSearchResult.h"
#import "WMFRandomArticleViewController.h"
#import "UIViewController+WMFArticlePresentation.h"

@interface WMFFirstRandomViewController ()

@end

@implementation WMFFirstRandomViewController

- (nonnull instancetype)initWithSiteURL:(nonnull NSURL *)siteURL dataStore:(nonnull MWKDataStore *)dataStore previewStore:(nonnull WMFArticleDataStore *)previewStore {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.siteURL = siteURL;
        self.dataStore = dataStore;
        self.previewStore = previewStore;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    NSParameterAssert(self.previewStore);
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
            NSURL *titleURL = [siteURL wmf_URLWithTitle:result.displayTitle];
            WMFRandomArticleViewController *randomArticleVC = [[WMFRandomArticleViewController alloc] initWithArticleURL:titleURL dataStore:self.dataStore previewStore:self.previewStore];
#if WMF_TWEAKS_ENABLED
            randomArticleVC.permaRandomMode = self.isPermaRandomMode;
#endif
            NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
            [viewControllers replaceObjectAtIndex:viewControllers.count - 1 withObject:randomArticleVC];
            [self.navigationController setViewControllers:viewControllers];
        }];
}

@end

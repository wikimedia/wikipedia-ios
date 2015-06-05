
#import "WMFAppViewController.h"
#import "WMFStyleManager.h"
#import "WMFSearchViewController.h"
#import "WMFArticleListCollectionViewController.h"
#import "DataMigrationProgressViewController.h"

NSString* const WMFDefaultStoryBoardName = @"iPhone_Root";

@implementation UIStoryboard (WMFDefaultStoryBoard)

+ (UIStoryboard*)wmf_defaultStoryBoard {
    return [UIStoryboard storyboardWithName:WMFDefaultStoryBoardName bundle:nil];
}

@end

@interface WMFAppViewController ()

@property (nonatomic, strong) IBOutlet UIView* splashView;
@property (nonatomic, strong) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, strong) WMFSearchViewController* searchViewController;


@end

@implementation WMFAppViewController

#pragma mark - Setup

+ (WMFAppViewController*)initialAppViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard wmf_defaultStoryBoard] instantiateInitialViewController];
}

- (void)launchAppInWindow:(UIWindow*)window {
    [window setRootViewController:self];
    [window makeKeyAndVisible];
}

- (void)resumeApp {
    //TODO: restore any UI, show Today
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self showSplashView];

    [self runDataMigrationIfNeededWithCompletion:^{
        [self hideSplashViewAnimated:YES];
        [self loadMainUI];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListCollectionViewController class]]) {
        self.listViewController = segue.destinationViewController;
    }
    if ([segue.destinationViewController isKindOfClass:[WMFSearchViewController class]]) {
        self.searchViewController = segue.destinationViewController;
    }
}

#pragma mark - Splash

- (void)showSplashView {
    self.splashView.hidden          = NO;
    self.splashView.layer.transform = CATransform3DIdentity;
    self.splashView.alpha           = 1.0;
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.3 : 0.0;


    [UIView animateWithDuration:duration animations:^{
        self.splashView.layer.transform = CATransform3DMakeScale(10.0f, 10.0f, 1.0f);
        self.splashView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.splashView.hidden = YES;
        self.splashView.layer.transform = CATransform3DIdentity;
    }];
}

- (BOOL)isShowingSplashView {
    return self.splashView.hidden == NO;
}

- (void)loadMainUI {
    //TODO: Tell embeded VCs to load their data
}

#pragma mark - Migration

- (void)runDataMigrationIfNeededWithCompletion:(dispatch_block_t)completion {
    DataMigrationProgressViewController* migrationVC = [[DataMigrationProgressViewController alloc] init];
    [migrationVC removeOldDataBackupIfNeeded];

    if (![migrationVC needsMigration]) {
        if (completion) {
            completion();
        }
        return;
    }

    [self presentViewController:migrationVC animated:YES completion:^{
        [migrationVC runMigrationWithCompletion:^(BOOL migrationCompleted) {
            [migrationVC dismissViewControllerAnimated:YES completion:NULL];
            if (completion) {
                completion();
            }
        }];
    }];
}

@end

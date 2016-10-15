#import "WMFWelcomeAnalyticsViewController.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFOpenExternalUrl.h"

@interface WMFWelcomeAnalyticsViewController ()

@property (strong, nonatomic) IBOutlet WelcomeAnalyticsAnimationView *animationView;

@end

@implementation WMFWelcomeAnalyticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.animationView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated {
    BOOL shouldAnimate = !self.hasAlreadyFaded;
    [super viewDidAppear:animated];
    if (shouldAnimate) {
        [self.animationView beginAnimations];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[WMFWelcomePanelViewController class]]){
        [((WMFWelcomePanelViewController*)segue.destinationViewController) useUsageReportsConfiguration];
    }
}

- (IBAction)showPrivacyPolicy:(id)sender {
    [self wmf_openExternalUrl:[NSURL URLWithString:URL_PRIVACY_POLICY]];
}

@end

#import "WMFWelcomeIntroductionViewController.h"
#import "Wikipedia-Swift.h"

@interface WMFWelcomeIntroductionViewController ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *tellMeMoreButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet WelcomeIntroAnimationView *animationView;

@end

@implementation WMFWelcomeIntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text =
        [MWLocalizedString(@"welcome-explore-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];

    self.subTitleLabel.text =
        MWLocalizedString(@"welcome-explore-sub-title", nil);

    [self.tellMeMoreButton setTitle:MWLocalizedString(@"welcome-explore-tell-me-more", nil)
                           forState:UIControlStateNormal];

    [self.nextButton setTitle:[MWLocalizedString(@"welcome-explore-continue-button", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]
                     forState:UIControlStateNormal];

    self.animationView.backgroundColor = [UIColor clearColor];
}

- (IBAction)showHowThisWorksAlert:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:MWLocalizedString(@"welcome-explore-tell-me-more-about-explore", nil) message:[NSString stringWithFormat:@"%@\n\n%@", MWLocalizedString(@"welcome-explore-tell-me-more-related", nil), MWLocalizedString(@"welcome-explore-tell-me-more-privacy", nil)] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"welcome-explore-tell-me-more-done-button", nil) style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated {
    BOOL shouldAnimate = !self.hasAlreadyFaded;
    [super viewDidAppear:animated];
    if (shouldAnimate) {
        [self.animationView beginAnimations];
    }
}

@end

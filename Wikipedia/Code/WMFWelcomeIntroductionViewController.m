
#import "WMFWelcomeIntroductionViewController.h"
#import "Wikipedia-Swift.h"

@interface WMFWelcomeIntroductionViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* subTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton* tellMeMoreButton;
@property (strong, nonatomic) IBOutlet UIButton* nextButton;
@property (strong, nonatomic) IBOutlet UIView* animationView;

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

    [self.nextButton setTitleColor:[UIColor wmf_blueTintColor] forState:UIControlStateNormal];

    [self.animationView wmf_configureForIntroAnimation];
}

- (IBAction)showHowThisWorksAlert:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"welcome-explore-tell-me-more-about-explore", nil) message:MWLocalizedString(@"welcome-explore-tell-me-more-details", nil) delegate:nil cancelButtonTitle:MWLocalizedString(@"welcome-explore-tell-me-more-done-button", nil) otherButtonTitles:nil];
    [alert show];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

@end

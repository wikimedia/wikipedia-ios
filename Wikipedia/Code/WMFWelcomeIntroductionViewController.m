
#import "WMFWelcomeIntroductionViewController.h"
@interface WMFWelcomeIntroductionViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* whatsNewLabel;
@property (strong, nonatomic) IBOutlet UILabel* topBulletTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel* topBulletDetailLabel;
@property (strong, nonatomic) IBOutlet UIButton* howThisWorksButton;
@property (strong, nonatomic) IBOutlet UILabel* bottomBulletTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel* bottomBulletDetailLabel;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;

@end


@implementation WMFWelcomeIntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text              = MWLocalizedString(@"welcome-whats-new-title", nil);
    self.whatsNewLabel.text           = MWLocalizedString(@"welcome-whats-new-whats-new", nil);
    self.topBulletTitleLabel.text     = MWLocalizedString(@"welcome-whats-new-bullet-one-title", nil);
    self.topBulletDetailLabel.text    = MWLocalizedString(@"welcome-whats-new-bullet-one-text", nil);
    self.bottomBulletTitleLabel.text  = MWLocalizedString(@"welcome-whats-new-bullet-two-title", nil);
    self.bottomBulletDetailLabel.text = MWLocalizedString(@"welcome-whats-new-bullet-two-text", nil);
    [self.howThisWorksButton setTitle:MWLocalizedString(@"welcome-whats-new-bullet-one-more-info-button-text", nil) forState:UIControlStateNormal];
    [self.nextStepButton setTitle:MWLocalizedString(@"welcome-whats-new-button-title", nil) forState:UIControlStateNormal];
}

- (IBAction)showHowThisWorksAlert:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"welcome-whats-new-bullet-one-more-info-button-text", nil) message:MWLocalizedString(@"welcome-whats-new-bullet-one-more-info-text", nil) delegate:nil cancelButtonTitle:MWLocalizedString(@"welcome-whats-new-bullet-one-more-info-done-button", nil) otherButtonTitles:nil];
    [alert show];
}

@end

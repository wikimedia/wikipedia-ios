
#import "WMFWelcomeIntroductionViewController.h"
@interface WMFWelcomeIntroductionViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* subTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton* tellMeMoreButton;
@property (strong, nonatomic) IBOutlet UIButton* nextButton;

@end


@implementation WMFWelcomeIntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text    =
    [MWLocalizedString(@"welcome-explore-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    
    self.subTitleLabel.text =
    MWLocalizedString(@"welcome-explore-sub-title", nil);

    [self.tellMeMoreButton setTitle:MWLocalizedString(@"welcome-explore-tell-me-more", nil)
                           forState:UIControlStateNormal];
    
    [self.nextButton setTitle:[MWLocalizedString(@"welcome-explore-continue-button", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]
                     forState:UIControlStateNormal];
}

- (IBAction)showHowThisWorksAlert:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"welcome-explore-tell-me-more", nil) message:MWLocalizedString(@"welcome-explore-tell-me-more-details", nil) delegate:nil cancelButtonTitle:MWLocalizedString(@"welcome-explore-tell-me-more-done-button", nil) otherButtonTitles:nil];
    [alert show];
}

@end

#import "WMFWelcomeLanguageViewController_Testing.h"
#import "Wikipedia-Swift.h"

@interface WMFWelcomeLanguageViewController ()

@property (strong, nonatomic) IBOutlet WelcomeLanguagesAnimationView *animationView;

@end

@implementation WMFWelcomeLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.animationView.backgroundColor = [UIColor clearColor];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[WMFWelcomePanelViewController class]]){
        [((WMFWelcomePanelViewController*)segue.destinationViewController) useLanguagesConfiguration];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    BOOL shouldAnimate = !self.hasAlreadyFaded;
    [super viewDidAppear:animated];
    if (shouldAnimate) {
        [self.animationView beginAnimations];
    }
}

@end

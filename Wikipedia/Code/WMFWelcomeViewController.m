
#import "WMFWelcomeViewController.h"
#import "WMFWelcomeIntroductionViewController.h"

@interface WMFWelcomeViewController ()

@property (nonatomic, strong) UINavigationController* welcomeNavigationController;

@end

@implementation WMFWelcomeViewController

+ (instancetype)welcomeViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard storyboardWithName:@"WMFWelcome" bundle:nil] instantiateInitialViewController];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        self.welcomeNavigationController = segue.destinationViewController;
    }
}

- (IBAction)dismiss:(id)sender {
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end

#import "WMFWelcomeViewController.h"
#import "WMFWelcomeIntroductionViewController.h"
#import "WMFBoringNavigationTransition.h"

@interface WMFWelcomeViewController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, strong) UINavigationController *welcomeNavigationController;

@end

@implementation WMFWelcomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.welcomeNavigationController.interactivePopGestureRecognizer.delegate = self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  return YES;
}

+ (instancetype)welcomeViewControllerFromDefaultStoryBoard {
  return [[UIStoryboard storyboardWithName:@"WMFWelcome" bundle:nil] instantiateInitialViewController];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
  return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
    self.welcomeNavigationController = segue.destinationViewController;
    self.welcomeNavigationController.delegate = self;
  }
}

- (IBAction)dismiss:(id)sender {
  dispatch_block_t completion = self.completionBlock;
  [self dismissViewControllerAnimated:YES
                           completion:^{
                             if (completion) {
                               completion();
                             }
                           }];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
  WMFBoringNavigationTransition *animation = [[WMFBoringNavigationTransition alloc] init];
  animation.operation = operation;
  return animation;
}

@end

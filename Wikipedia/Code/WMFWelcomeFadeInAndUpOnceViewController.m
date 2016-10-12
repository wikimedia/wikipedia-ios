#import "WMFWelcomeFadeInAndUpOnceViewController.h"
#import "UIView+WMFWelcomeFadeInAndUp.h"
#import "Wikipedia-Swift.h"

@interface WMFWelcomeFadeInAndUpOnceViewController ()

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSNumber *fadeInAndUpDelay;

@end

@implementation WMFWelcomeFadeInAndUpOnceViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.hasAlreadyFaded) {
        [self.containerView wmf_zeroLayerOpacity];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.hasAlreadyFaded) {
        [self.containerView wmf_fadeInAndUpAfterDelay:[self.fadeInAndUpDelay floatValue]];
    }
    self.hasAlreadyFaded = YES;
}

- (IBAction)next:(id)sender {
    [self.delegate showNextWelcomePage:self];
}

@end

#import "WMFWelcomeFadeInAndUpOnceViewController.h"
#import "UIView+WMFWelcomeFadeInAndUp.h"

@interface WMFWelcomeFadeInAndUpOnceViewController ()

@property (strong, nonatomic) IBOutlet UIView* containerView;
@property (nonatomic) BOOL hasAlreadyFaded;

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
        [self.containerView wmf_fadeInAndUpAfterDelay:0.1];
    }
    self.hasAlreadyFaded = YES;
}

@end

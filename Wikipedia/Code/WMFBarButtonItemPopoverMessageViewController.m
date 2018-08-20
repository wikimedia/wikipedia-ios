#import "WMFBarButtonItemPopoverMessageViewController.h"

@interface WMFBarButtonItemPopoverMessageViewController ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (strong, nonatomic) WMFTheme *theme;

@end

@implementation WMFBarButtonItemPopoverMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }
    [self.titleLabel setText:self.messageTitle];
    [self.messageLabel setText:self.message];
    [self.widthConstraint setConstant:self.width];
    [self applyTheme:self.theme];
}

- (CGSize)preferredContentSize {
    // Make the popover's dimensions result from the storyboard constraints, i.e. respect
    // dynamic height for localized strings which end up being long enough to wrap lines, etc.
    return [self.view systemLayoutSizeFittingSize:CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric)
                    withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
                          verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.view.backgroundColor = theme.colors.paperBackground;
    self.titleLabel.textColor = theme.colors.primaryText;
    self.messageLabel.textColor = theme.colors.secondaryText;
}

@end

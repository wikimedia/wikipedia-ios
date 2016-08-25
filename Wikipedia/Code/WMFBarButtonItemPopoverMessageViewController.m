#import "WMFBarButtonItemPopoverMessageViewController.h"

@interface WMFBarButtonItemPopoverMessageViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* messageLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* widthConstraint;

@end

@implementation WMFBarButtonItemPopoverMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.titleLabel setText:self.messageTitle];
    [self.messageLabel setText:self.message];
    [self.widthConstraint setConstant:self.width];
}

- (CGSize) preferredContentSize {
    // Make the popover's dimensions result from the storyboard constraints, i.e. respect
    // dynamic height for localized strings which end up being long enough to wrap lines, etc.
    // Works with both iOS 8 and 9.
    return [self.view systemLayoutSizeFittingSize:CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric)
                    withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
                          verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController*)controller {
    return UIModalPresentationNone;
}

@end

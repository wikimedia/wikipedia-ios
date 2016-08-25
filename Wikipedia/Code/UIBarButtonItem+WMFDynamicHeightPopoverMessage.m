#import "UIBarButtonItem+WMFDynamicHeightPopoverMessage.h"
#import "WMFBarButtonItemPopoverMessageViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFBarButtonItemPopoverBackgroundView.h"
#import "UIColor+WMFStyle.h"

@implementation UIBarButtonItem (WMFDynamicHeightPopoverMessage)

- (UIViewController*)wmf_dynamicHeightPopoverViewControllerWithTitle:(NSString*)title
                                                             message:(NSString*)message
                                                               width:(CGFloat)width {
    
    WMFBarButtonItemPopoverMessageViewController* popoverVC =
        [WMFBarButtonItemPopoverMessageViewController wmf_initialViewControllerFromClassStoryboard];
    
    popoverVC.modalPresentationStyle = UIModalPresentationPopover;
    popoverVC.messageTitle           = title;
    popoverVC.message                = message;
    popoverVC.width                  = width;
    
    popoverVC.view.backgroundColor = [UIColor wmf_barButtonItemPopoverMessageBackgroundColor];

    UIPopoverPresentationController* presenter = [popoverVC popoverPresentationController];

    presenter.delegate                   = popoverVC;
    presenter.barButtonItem              = self;
    presenter.popoverBackgroundViewClass = [WMFBarButtonItemPopoverBackgroundView class];
    
    return popoverVC;
}

@end

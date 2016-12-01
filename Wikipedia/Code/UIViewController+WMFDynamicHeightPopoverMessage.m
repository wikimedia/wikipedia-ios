#import "UIViewController+WMFDynamicHeightPopoverMessage.h"
#import "WMFBarButtonItemPopoverMessageViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFBarButtonItemPopoverBackgroundView.h"
#import "UIColor+WMFStyle.h"

typedef void (^WMFDynamicHeightPopoverPresentationHandler)(UIPopoverPresentationController *presenter);

@implementation UIViewController (WMFDynamicHeightPopoverMessage)

- (void)wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:(UIBarButtonItem *)item
                                                            withTitle:(NSString *)title
                                                              message:(NSString *)message
                                                                width:(CGFloat)width
                                                             duration:(NSTimeInterval)duration {

    [self wmf_presentDynamicHeightPopoverViewControllerWithTitle:title
                                                         message:message
                                                           width:width
                                                        duration:duration
                                 withPresenterConfigurationBlock:^(UIPopoverPresentationController *presenter) {
                                     [presenter setBarButtonItem:item];
                                 }];
}

- (void)wmf_presentDynamicHeightPopoverViewControllerForSourceRect:(CGRect)sourceRect
                                                         withTitle:(NSString *)title
                                                           message:(NSString *)message
                                                             width:(CGFloat)width
                                                          duration:(NSTimeInterval)duration {

    [self wmf_presentDynamicHeightPopoverViewControllerWithTitle:title
                                                         message:message
                                                           width:width
                                                        duration:duration
                                 withPresenterConfigurationBlock:^(UIPopoverPresentationController *presenter) {
                                     [presenter setSourceView:self.view];
                                     [presenter setSourceRect:sourceRect];
                                 }];
}

- (void)wmf_presentDynamicHeightPopoverViewControllerWithTitle:(NSString *)title
                                                       message:(NSString *)message
                                                         width:(CGFloat)width
                                                      duration:(NSTimeInterval)duration
                               withPresenterConfigurationBlock:(WMFDynamicHeightPopoverPresentationHandler)presenterConfigurationBlock {

    if (self.navigationController.visibleViewController != self) {
        return;
    }

    UIViewController *popoverVC = [self wmf_dynamicHeightPopoverViewControllerWithTitle:title
                                                                                message:message
                                                                                  width:width
                                                        withPresenterConfigurationBlock:presenterConfigurationBlock];
    [self presentViewController:popoverVC
                       animated:NO
                     completion:^{
                         if (duration > 0) {
                             [self performSelector:@selector(dismissPopover:) withObject:popoverVC afterDelay:duration];
                         }
                     }];
}

- (void)dismissPopover:(UIViewController *)popoverVC {
    // Ensure the popover is still the presented view controller.
    if (self.presentedViewController == popoverVC) {
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }
}

- (UIViewController *)wmf_dynamicHeightPopoverViewControllerWithTitle:(NSString *)title
                                                              message:(NSString *)message
                                                                width:(CGFloat)width
                                      withPresenterConfigurationBlock:(WMFDynamicHeightPopoverPresentationHandler)presenterConfigurationBlock {

    WMFBarButtonItemPopoverMessageViewController *popoverVC =
        [WMFBarButtonItemPopoverMessageViewController wmf_initialViewControllerFromClassStoryboard];

    popoverVC.modalPresentationStyle = UIModalPresentationPopover;
    popoverVC.messageTitle = title;
    popoverVC.message = message;
    popoverVC.width = width;

    popoverVC.view.backgroundColor = [UIColor wmf_barButtonItemPopoverMessageBackgroundColor];

    UIPopoverPresentationController *presenter = [popoverVC popoverPresentationController];

    presenter.delegate = popoverVC;
    presenter.passthroughViews = @[self.view];

    if (presenterConfigurationBlock) {
        presenterConfigurationBlock(presenter);
    }

    presenter.popoverBackgroundViewClass = [WMFBarButtonItemPopoverBackgroundView class];

    return popoverVC;
}

@end

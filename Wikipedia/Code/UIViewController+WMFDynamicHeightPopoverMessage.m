#import "UIViewController+WMFDynamicHeightPopoverMessage.h"
#import "WMFBarButtonItemPopoverMessageViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
@import WMF;

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

    UIPopoverPresentationController *presenter = [popoverVC popoverPresentationController];

    presenter.delegate = popoverVC;

    if (presenterConfigurationBlock) {
        presenterConfigurationBlock(presenter);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(theme)]) {
        id maybeTheme = [(id)self performSelector:@selector(theme)];
        if ([maybeTheme isKindOfClass:[WMFTheme class]]) {
            [popoverVC applyTheme:maybeTheme];
            presenter.backgroundColor = [(WMFTheme *)maybeTheme colors].paperBackground;
        }
    }
#pragma clang diagnostic pop

    return popoverVC;
}

@end

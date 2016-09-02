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
                                                                width:(CGFloat)width {

    [self wmf_presentDynamicHeightPopoverViewControllerWithTitle:title
                                                         message:message
                                                           width:width
                                 withPresenterConfigurationBlock:^(UIPopoverPresentationController *presenter) {
                                     [presenter setBarButtonItem:item];
                                 }];
}

- (void)wmf_presentDynamicHeightPopoverViewControllerForSourceRect:(CGRect)sourceRect
                                                         withTitle:(NSString *)title
                                                           message:(NSString *)message
                                                             width:(CGFloat)width {

    [self wmf_presentDynamicHeightPopoverViewControllerWithTitle:title
                                                         message:message
                                                           width:width
                                 withPresenterConfigurationBlock:^(UIPopoverPresentationController *presenter) {
                                     [presenter setSourceView:self.view];
                                     [presenter setSourceRect:sourceRect];
                                 }];
}

- (void)wmf_presentDynamicHeightPopoverViewControllerWithTitle:(NSString *)title
                                                       message:(NSString *)message
                                                         width:(CGFloat)width
                               withPresenterConfigurationBlock:(WMFDynamicHeightPopoverPresentationHandler)presenterConfigurationBlock {

    [self presentViewController:
              [self wmf_dynamicHeightPopoverViewControllerWithTitle:title
                                                            message:message
                                                              width:width
                                    withPresenterConfigurationBlock:presenterConfigurationBlock]
                       animated:NO
                     completion:nil];
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

    if (presenterConfigurationBlock) {
        presenterConfigurationBlock(presenter);
    }

    presenter.popoverBackgroundViewClass = [WMFBarButtonItemPopoverBackgroundView class];

    return popoverVC;
}

@end

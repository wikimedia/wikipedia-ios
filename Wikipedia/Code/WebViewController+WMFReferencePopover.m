#import "WebViewController+WMFReferencePopover.h"
#import "WMFReferencePopoverMessageViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFReferenceLinkTappedNotification = @"WMFReferenceLinkTappedNotification";

typedef void (^WMFReferencePopoverPresentationHandler)(UIPopoverPresentationController *presenter);

@implementation WebViewController (WMFReferencePopover)

- (void)wmf_presentReferencePopoverViewControllerForReference:(WMFReference *)reference
                                                        width:(CGFloat)width {
    [self wmf_dismissReferencePopoverAnimated:NO
                                   completion:^{
                                       [self wmf_presentReferencePopoverViewControllerWithReference:reference
                                                                                              width:width
                                                                    withPresenterConfigurationBlock:^(UIPopoverPresentationController *presenter) {
                                                                        [presenter setSourceView:self.webView];
                                                                        [presenter setSourceRect:reference.rect];
                                                                    }];
                                   }];
}

- (void)wmf_presentReferencePopoverViewControllerWithReference:(WMFReference *)reference
                                                         width:(CGFloat)width
                               withPresenterConfigurationBlock:(WMFReferencePopoverPresentationHandler)presenterConfigurationBlock {

    WMFReferencePopoverMessageViewController *popoverVC = [self wmf_referencePopoverViewControllerWithReference:reference
                                                                                                          width:width
                                                                                withPresenterConfigurationBlock:presenterConfigurationBlock];
    [popoverVC applyTheme:self.theme];

    [self presentViewController:popoverVC
                       animated:NO
                     completion:^{

                         // Reminder: The textView's scrollEnabled needs to remain "NO" until after the popover is
                         // presented. (When scrollEnabled is NO the popover can better determine the textView's
                         // full content height.) See the third reference "[3]" on "enwiki > Pythagoras".
                         NSAssert(popoverVC.scrollEnabled == NO, @"scrollEnabled must be NO until the popover is presented");
                         popoverVC.scrollEnabled = YES;

                     }];
}

- (WMFReferencePopoverMessageViewController *)wmf_referencePopoverViewControllerWithReference:(WMFReference *)reference
                                                                                        width:(CGFloat)width
                                                              withPresenterConfigurationBlock:(WMFReferencePopoverPresentationHandler)presenterConfigurationBlock {

    WMFReferencePopoverMessageViewController *popoverVC =
        [WMFReferencePopoverMessageViewController wmf_initialViewControllerFromClassStoryboard];

    [popoverVC applyTheme:self.theme];

    popoverVC.modalPresentationStyle = UIModalPresentationPopover;
    popoverVC.reference = reference;
    popoverVC.width = width;

    popoverVC.view.backgroundColor = self.theme.colors.paperBackground;

    UIPopoverPresentationController *presenter = [popoverVC popoverPresentationController];
    presenter.passthroughViews = @[self.webView];
    presenter.delegate = popoverVC;
    presenter.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;

    if (presenterConfigurationBlock) {
        presenterConfigurationBlock(presenter);
    }

    presenter.backgroundColor = self.theme.colors.paperBackground;

    return popoverVC;
}

- (void)wmf_dismissReferencePopoverAnimated:(BOOL)flag completion:(void (^__nullable)(void))completion {
    if ([self.presentedViewController isMemberOfClass:[WMFReferencePopoverMessageViewController class]] || [self.presentedViewController isMemberOfClass:[WMFReferencePageViewController class]]) {
        [self dismissViewControllerAnimated:flag completion:completion];
    } else {
        if (completion) {
            completion();
        }
    }
}

@end

NS_ASSUME_NONNULL_END

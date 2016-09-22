#import "WebViewController+WMFReferencePopover.h"
#import "WMFReferencePopoverMessageViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFReferencePopoverBackgroundView.h"
#import "UIColor+WMFStyle.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFReferenceLinkTappedNotification = @"WMFReferenceLinkTappedNotification";

typedef void (^WMFReferencePopoverPresentationHandler)(UIPopoverPresentationController *presenter);

@implementation WebViewController (WMFReferencePopover)

- (void)wmf_presentReferencePopoverViewControllerForSourceRect:(CGRect)sourceRect
                                                      linkText:(nullable NSString *)linkText
                                                 referenceHTML:(nullable NSString *)html
                                                         width:(CGFloat)width {
    [self wmf_dismissReferencePopoverAnimated:NO completion:^{
        [self wmf_presentReferencePopoverViewControllerWithHTML:html
                                                       linkText:linkText
                                                          width:width
                                withPresenterConfigurationBlock:^(UIPopoverPresentationController *presenter) {
                                    [presenter setSourceView:self.webView];
                                    [presenter setSourceRect:sourceRect];
                                }];
    }];
}

- (void)wmf_presentReferencePopoverViewControllerWithHTML:(nullable NSString *)html
                                                 linkText:(nullable NSString *)linkText
                                                    width:(CGFloat)width
                          withPresenterConfigurationBlock:(WMFReferencePopoverPresentationHandler)presenterConfigurationBlock {
    
    WMFReferencePopoverMessageViewController *popoverVC = [self wmf_referencePopoverViewControllerWithHTML:html
                                                                                                  linkText:linkText
                                                                                                     width:width
                                                                           withPresenterConfigurationBlock:presenterConfigurationBlock];

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

- (WMFReferencePopoverMessageViewController *)wmf_referencePopoverViewControllerWithHTML:(nullable NSString *)html
                                                                                linkText:(nullable NSString *)linkText
                                                                                   width:(CGFloat)width
                                                         withPresenterConfigurationBlock:(WMFReferencePopoverPresentationHandler)presenterConfigurationBlock {
    
    WMFReferencePopoverMessageViewController *popoverVC =
    [WMFReferencePopoverMessageViewController wmf_initialViewControllerFromClassStoryboard];
    
    popoverVC.modalPresentationStyle = UIModalPresentationPopover;
    popoverVC.linkText = linkText;
    popoverVC.referenceHTML = html;
    popoverVC.width = width;
    
    popoverVC.view.backgroundColor = [UIColor wmf_referencePopoverBackgroundColor];
    
    UIPopoverPresentationController *presenter = [popoverVC popoverPresentationController];
    presenter.passthroughViews = @[self.webView];
    presenter.delegate = popoverVC;
    presenter.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;

    if (presenterConfigurationBlock) {
        presenterConfigurationBlock(presenter);
    }
    
    presenter.popoverBackgroundViewClass = [WMFReferencePopoverBackgroundView class];
    
    return popoverVC;
}

- (void)wmf_dismissReferencePopoverAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion {
    if ([self.presentedViewController isMemberOfClass:[WMFReferencePopoverMessageViewController class]]) {
        [self dismissViewControllerAnimated:flag completion:completion];
    }else{
        if(completion){
            completion();
        }
    }
}

@end

NS_ASSUME_NONNULL_END

@import UIKit;
#import "WMFArticleListItemController.h"

@class WMFArticleContainerViewController;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePopupTransition : UIPercentDrivenInteractiveTransition
    <UIViewControllerAnimatedTransitioning>

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak, readonly) UIViewController* presentingViewController;
@property (nonatomic, weak) WMFArticleContainerViewController* presentedViewController;

/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

/**
 *  Controls how much of `presentedViewController` is vertically "popped up" when the transition begins.
 *
 *  Default is 300.0
 */
@property (assign, nonatomic) CGFloat popupHeight;

/**
 *  Set to NO to disable interactive presentation
 *  Default is YES
 */
@property (assign, nonatomic) BOOL presentInteractively;

/**
 *  Set to NO to disable interactive dismissal
 *  Default is YES
 */
@property (assign, nonatomic) BOOL dismissInteractively;

@end

NS_ASSUME_NONNULL_END


@import UIKit;
#import "WMFArticleListItemController.h"

@class WMFArticleContainerViewController;

@interface WMFArticlePopupTransition : UIPercentDrivenInteractiveTransition
    <UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) UIViewController* presentingViewController;
@property (nonatomic, weak) WMFArticleContainerViewController* presentedViewController;

/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

/**
 *  Set to control the height of the popup.
 *  Set before presenting
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

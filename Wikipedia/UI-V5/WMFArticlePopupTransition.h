
@import UIKit;


#import <UIKit/UIKit.h>

@interface WMFArticlePopupTransition : UIPercentDrivenInteractiveTransition <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController presentedViewController:(UIViewController*)presentedViewController contentScrollView:(UIScrollView*)scrollView;

@property (nonatomic, weak, readonly) UIViewController* presentingViewController;
@property (nonatomic, weak, readonly) UIViewController* presentedViewController;
@property (nonatomic, weak, readonly) UIScrollView* scrollView;

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

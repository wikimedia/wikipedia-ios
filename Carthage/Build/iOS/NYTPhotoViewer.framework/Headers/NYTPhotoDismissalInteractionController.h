//
//  NYTPhotoDismissalInteractionController.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/17/15.
//
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  An object that controls an interactive photo dismissal transition.
 */
@interface NYTPhotoDismissalInteractionController : NSObject <UIViewControllerInteractiveTransitioning>

/**
 *  The animator object associated with the interactive transition.
 */
@property (nonatomic) id <UIViewControllerAnimatedTransitioning> animator;

/**
 *  If set, this view will be hidden as soon as the interactive transition starts, and shown after it ends.
 */
@property (nonatomic, nullable) UIView *viewToHideWhenBeginningTransition;

/**
 *  A `BOOL` determining whether, after reaching a certain panning threshold that constitutes a dismissal, the animator object should be used to finish the transition.
 */
@property (nonatomic) BOOL shouldAnimateUsingAnimator;

/**
 *  Call when new events are received from a `UIPanGestureRecognizer`. Pans the appropriate view, and makes decisions when to finish or cancel the interactive transition back to the anchor point. Intended to be called after a dismissal has started with `dismissViewControllerAnimated:completion:`.
 *
 *  @param panGestureRecognizer The `UIPanGestureRecognizer` that caused the pan event.
 *  @param viewToPan            The view to pan using the location from the pan gesture recognizer.
 *  @param anchorPoint          The point at which the pan began and should end if cancelled. Should be in the coordinates of the "from" view controller's view on dismissal.
 */
- (void)didPanWithPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer viewToPan:(UIView *)viewToPan anchorPoint:(CGPoint)anchorPoint;

@end

NS_ASSUME_NONNULL_END
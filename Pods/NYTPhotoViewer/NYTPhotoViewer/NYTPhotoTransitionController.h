//
//  NYTPhotoTransitionController.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/13/15.
//
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  An object that manages both animated transitions and interactive transitions, acting as the transitioning delegate and internally coordinating multiple objects that do the animating and interactivity work.
 */
@interface NYTPhotoTransitionController : NSObject <UIViewControllerTransitioningDelegate>

/**
 *  The view from which to start an image zooming transition. This view may be hidden or shown in the transition, but will never be removed or changed in its view hierarchy.
 */
@property (nonatomic) UIView *startingView;

/**
 *  The view from which to end an image zooming transition. This view may be hidden or shown in the transition, but will never be removed or changed in its view hierarchy.
 */
@property (nonatomic) UIView *endingView;

/**
 *  Forces the dismiss to animate, instead of the default behavior of being interactive.
 */
@property (nonatomic) BOOL forcesNonInteractiveDismissal;

/**
 *  Call when new events are received from a `UIPanGestureRecognizer`. Internally passes off to interaction controller, which pans the appropriate view, and makes decisions when to finish or cancel the interactive transition back to the anchor point. Intended to be called after a dismissal has started with `dismissViewControllerAnimated:completion:`.
 *
 *  @param panGestureRecognizer The `UIPanGestureRecognizer` that caused the pan event.
 *  @param viewToPan            The view to pan using the location from the pan gesture recognizer.
 *  @param anchorPoint          The point at which the pan began and should end if cancelled. Should be in the coordinates of the "from" view controller's view on dismissal.
 */
- (void)didPanWithPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer viewToPan:(UIView *)viewToPan anchorPoint:(CGPoint)anchorPoint;

@end

NS_ASSUME_NONNULL_END
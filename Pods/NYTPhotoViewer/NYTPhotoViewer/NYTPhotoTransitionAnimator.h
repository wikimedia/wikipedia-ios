//
//  NYTPhotoTransitionAnimator.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/17/15.
//
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  An object that controls the animated transition of photo presentation and dismissal.
 */
@interface NYTPhotoTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

/**
 *  The view from which to start an image zooming transition. This view may be hidden or shown in the transition, but will never be removed or changed in its view hierarchy.
 */
@property (nonatomic) UIView *startingView;

/**
 *  The view from which to end an image zooming transition. This view may be hidden or shown in the transition, but will never be removed or changed in its view hierarchy.
 */
@property (nonatomic) UIView *endingView;

/**
 *  The view that is used for animating the starting view. If no view is set, the starting view is screenshotted and the relevant properties are copied to the new view.
 */
@property (nonatomic, nullable) UIView *startingViewForAnimation;

/**
 *  The view that is used for animating the ending view. If no view is set, the ending view is screenshotted and relevant properties copied to the new view.
 */
@property (nonatomic, nullable) UIView *endingViewForAnimation;

/**
 *  Whether this transition is a dismissal. If `NO`, presentation is assumed.
 */
@property (nonatomic, getter=isDismissing) BOOL dismissing;

/**
 *  The duration of the animation when zooming is performed.
 */
@property (nonatomic) CGFloat animationDurationWithZooming;

/**
 *  The duration of the animation when only fading and not zooming is performed.
 */
@property (nonatomic) CGFloat animationDurationWithoutZooming;

/**
 *  The ratio (from 0.0 to 1.0) of the total animation duration that the background fade duration takes.
 */
@property (nonatomic) CGFloat animationDurationFadeRatio;

/**
 *  The ratio (from 0.0 to 1.0) of the total animation duration that the ending view fade in duration takes.
 */
@property (nonatomic) CGFloat animationDurationEndingViewFadeInRatio;

/**
 *  The ratio (from 0.0 to 1.0) of the total animation duration that the starting view fade out duration takes after the ending view fade in completes.
 */
@property (nonatomic) CGFloat animationDurationStartingViewFadeOutRatio;

/**
 *  The value passed as the spring damping argument to `animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:` for the zooming animation.
 */
@property (nonatomic) CGFloat zoomingAnimationSpringDamping;

/**
 *  Convenience method for creating a view for animation from another arbitrary view. Attempts to create an identical view in the most efficient way possible. Returns `nil` if the passed-in view is `nil`.
 *
 *  @param view The view from which to create the animation.
 *
 *  @return A new view identical in appearance to the passed-in view, with relevant properties transferred. Not a member of any view hierarchy. Return `nil` if the passed-in view is `nil`.
 */
+ (nullable UIView *)newAnimationViewFromView:(nullable UIView *)view;

@end

NS_ASSUME_NONNULL_END

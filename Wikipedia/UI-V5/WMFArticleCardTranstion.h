
#import <Foundation/Foundation.h>
@import UIKit;

@interface WMFArticleCardTranstion : UIPercentDrivenInteractiveTransition <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

/**
 *  Y Distance to the next card that overlaps the animating card.
 *  The transisition uses this information for snapshoting purposes.
 */
@property (assign, nonatomic) CGFloat offsetOfNextOverlappingCard;

/**
 *  The view to be transistioned into the presented view.
 *  This view will be snapshotted.
 */
@property (strong, nonatomic) UIView* movingCardView;

/**
 *  The y offset of the final postiion of the presented card in the presented view frame.
 *  This is used to calculate the final frame of the moving card view.
 *
 *  This is useful for conveying things like content inset in the presented view controller.
 *  This is used instead of frame because the full frame is difficult to know before presentation begins.
 */
@property (assign, nonatomic) CGFloat presentCardOffset;

/**
 *  Is the transisiton dismissing?
 */
@property (nonatomic, assign, readonly) BOOL isDismissing;

/**
 *  Is the transition Presenting?
 *  (Convienence, just !self.isDismissing)
 */
@property (nonatomic, assign, readonly) BOOL isPresenting;

@end

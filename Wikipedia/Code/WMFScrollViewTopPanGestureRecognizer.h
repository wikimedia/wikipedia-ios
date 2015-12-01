
#import <UIKit/UIKit.h>

@interface WMFScrollViewTopPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, weak) UIScrollView* scrollView;

/**
 *  Whether or not the receiver has started tracking `aboveBoundsVerticalDisplacement`.
 *
 *  Check this property before retrieving `aboveBoundsVerticalDisplacement`.  The recognizer needs to record the user's
 *  touch location at the moment when `scrollView` passes `scrollView.contentInset.top`.  Until that touch location is
 *  recorded, it's not possible to report `aboveBoundsVerticalDisplacement` while also blocking further changes to
 *  the `contentOffset` of the receiver's `scrollView`.
 */
@property (nonatomic, assign, readonly, getter = isRecordingVerticalDisplacement) BOOL recordingVerticalDisplacement;

/**
 *  The vertical displacement past the top of `scrollView.contentInset.top`.
 *
 *  Once `scrollView` attempts to scroll beyond its `contentInset.top`, the receiver will block further scrolling up,
 *  reporting further dragging past that point in the value returned by this property.  When `scrollView` is scrolled down
 *
 *  @warning This will always return 0 unless `didStart == YES`.
 *
 *  @return The vertical displacement as described above. Positive indicates the user is scrolling up past
 *          `contentInset.top`, while a negative indicates downward scrolling.
 */
@property (nonatomic, assign, readonly) CGFloat aboveBoundsVerticalDisplacement;

@end


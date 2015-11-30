#import "WMFScrollViewTopPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#import "UIScrollView+WMFContentOffsetUtils.h"

@interface WMFScrollViewTopPanGestureRecognizer ()

/**
 *  Vertical touch coordinate recorded when `scrollView.contentOffset` goes beyond the top of its content.
 *
 *  Specifically, `scrollView.contentOffset.y < scrollView.contentInset.top`
 */
@property (nonatomic, assign) CGFloat initialVerticalOffset;

@property (nonatomic, assign, readwrite, getter = isRecordingVerticalDisplacement) BOOL recordingVerticalDisplacement;

@end

@implementation WMFScrollViewTopPanGestureRecognizer

- (CGFloat)aboveBoundsVerticalDisplacement {
    return self.isRecordingVerticalDisplacement ? ([self locationInView : self.view.window].y - self.initialVerticalOffset) : 0.0;
}

- (void)setRecordingVerticalDisplacement:(BOOL)recordingVerticalDisplacement {
    _recordingVerticalDisplacement = recordingVerticalDisplacement;
    self.initialVerticalOffset     = recordingVerticalDisplacement ? [self locationInView : self.view.window].y : 0.0;
}

- (void)reset {
    [super reset];
    self.recordingVerticalDisplacement = NO;
    self.scrollView.scrollEnabled      = YES;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    [super touchesMoved:touches withEvent:event];
    if (!self.scrollView || self.state != UIGestureRecognizerStateChanged) {
        return;
    }

    /*
       !!!: Only set recordingVerticalDisplacement to `NO` in `reset`, otherwise touch continuity will break during
          interactive transitions when the user scrolls below the top inset. IOW:

       1. User pulls down (scrolls up) to start dismissing
       2. User pushups content up (scrolls down), as if scrolling normally
       3. contentOffset becomes greater than contentInset.top
       4. Reset recognizer (we shouldn't do this)
       5. W/o lifting finger, user tries to pull down and start interactive transition again
       6. Nothing happens due to step 4
     */
    if (self.scrollView.contentOffset.y < self.scrollView.contentInset.top && !self.isRecordingVerticalDisplacement) {
        self.recordingVerticalDisplacement = YES;
        [self.scrollView wmf_scrollToTop:NO];
        self.scrollView.scrollEnabled = NO;
        /*
           setting the contentOffset here is not enough, as the panGestureRecognizer also sets the contentOffset, resulting
           in visual glitches while the view is being dragged. this unfortunately means scrolling is all or nothing with
           the current approach
         */
    }
}

@end


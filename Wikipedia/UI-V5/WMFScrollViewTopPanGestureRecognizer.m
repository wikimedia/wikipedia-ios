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

@property (nonatomic, assign, readwrite, getter=isRecordingVerticalDisplacement) BOOL recordingVerticalDisplacement;

@end

@implementation WMFScrollViewTopPanGestureRecognizer

- (CGFloat)aboveBoundsVerticalDisplacement {
    return self.isRecordingVerticalDisplacement ? ([self locationInView:self.view.window].y - self.initialVerticalOffset) : 0.0;
}

- (void)setRecordingVerticalDisplacement:(BOOL)recordingVerticalDisplacement {
    _recordingVerticalDisplacement = recordingVerticalDisplacement;
    self.initialVerticalOffset = recordingVerticalDisplacement ? [self locationInView:self.view.window].y : 0.0;
}

- (void)reset {
    [super reset];
    self.recordingVerticalDisplacement = NO;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    [super touchesMoved:touches withEvent:event];
    if (!self.scrollView || self.state != UIGestureRecognizerStateChanged) {
        return;
    }

    /*
     !!!: Only set recordingVerticalDisplacement to `NO` in `reset`, otherwise touch continuity will break during
          interactive transitions when the user scrolls below the top inset.
    */
    if (self.scrollView.contentOffset.y <= self.scrollView.contentInset.top && !self.isRecordingVerticalDisplacement) {
        self.recordingVerticalDisplacement = YES;
    }

    if (self.isRecordingVerticalDisplacement && self.aboveBoundsVerticalDisplacement >= 0.0) {
        // only block scrolling while tracking touches that would displace content beyond top inset
        [self.scrollView wmf_scrollToTop:NO];
    }
    /* 
     !!!: once we stop using snapshots, users will see content scroll normally below contentInset.top
     even after staring an interactive transition
    */
}

@end


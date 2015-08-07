#import "WMFScrollViewTopPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface WMFScrollViewTopPanGestureRecognizer ()
@property (nonatomic, assign) CGFloat startingOffset;
@property (nonatomic, assign, readwrite) BOOL didStart;
@end

@implementation WMFScrollViewTopPanGestureRecognizer

- (CGFloat)postBoundsTranslation {
    return self.didStart ? [self locationInView:self.view].y - self.startingOffset : 0.0;
}

- (void)reset {
    [super reset];
    DDLogVerbose(@"Recognizer resetting");
    self.didStart = NO;
    self.startingOffset = 0.0;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    [super touchesMoved:touches withEvent:event];

    if (!self.scrollview || self.state != UIGestureRecognizerStateChanged) {
        return;
    }

    BOOL isPastBounds = self.scrollview.contentOffset.y < self.scrollview.contentInset.top;
    if (isPastBounds && !self.didStart) {
        self.didStart = YES;
        self.startingOffset = [self locationInView:self.view].y;
        DDLogVerbose(@"Starting postBoundsTranslation tracking w/ offset %f", self.startingOffset);
        self.scrollview.contentOffset = CGPointMake(self.scrollview.contentInset.left,
                                                    self.scrollview.contentInset.top);
    }
    else if (self.didStart && self.scrollview.contentOffset.y > self.scrollview.contentInset.top) {
        DDLogVerbose(@"Reseting recognizer state to allow transition to restart when scrollview goes past bounds again.");
        /*
         if this isn't reset, the user won't be able to scroll normally after aborting a transition
        */
        self.state = UIGestureRecognizerStateCancelled;
    }
}

@end


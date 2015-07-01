#import "WMFScrollViewTopPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface WMFScrollViewTopPanGestureRecognizer ()
@property (nonatomic, strong) NSNumber* isFail;
@end

@implementation WMFScrollViewTopPanGestureRecognizer

- (void)reset {
    [super reset];
    self.isFail = nil;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    [super touchesMoved:touches withEvent:event];

    if (!self.scrollview) {
        return;
    }

    if (self.state == UIGestureRecognizerStateFailed) {
        return;
    }
    CGPoint nowPoint  = [touches.anyObject locationInView:self.view];
    CGPoint prevPoint = [touches.anyObject previousLocationInView:self.view];

    if (self.isFail) {
        if (self.isFail.boolValue) {
            self.state = UIGestureRecognizerStateFailed;
        }
        return;
    }

    CGFloat topVerticalOffset = -self.scrollview.contentInset.top;

    if (nowPoint.y > prevPoint.y && self.scrollview.contentOffset.y <= topVerticalOffset) {
        self.isFail = @NO;
    } else if (self.scrollview.contentOffset.y >= topVerticalOffset) {
        self.state  = UIGestureRecognizerStateFailed;
        self.isFail = @YES;
    } else {
        self.isFail = @NO;
    }
}

@end


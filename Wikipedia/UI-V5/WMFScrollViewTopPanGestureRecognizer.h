
#import <UIKit/UIKit.h>

@interface WMFScrollViewTopPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, weak) UIScrollView* scrollview;

@property (nonatomic, assign, readonly) CGFloat postBoundsTranslation;

@property (nonatomic, assign, readonly) BOOL didStart;

@end


@import UIKit;

typedef NS_ENUM(NSInteger, TabularScrollViewOrientation) {
    TabularScrollViewOrientationVertical = 0,
    TabularScrollViewOrientationHorizontal = 1
};

@interface TabularScrollView : UIScrollView

- (void)setTabularSubviews:(NSArray *)tabularSubviews;

@property (nonatomic) TabularScrollViewOrientation orientation;

@property (nonatomic) CGFloat minSubviewHeight;

@end

@import UIKit;

typedef NS_ENUM(NSInteger, TabularScrollViewOrientation) {
    TABULAR_SCROLLVIEW_LAYOUT_VERTICAL = 0,
    TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL = 1
};

@interface TabularScrollView : UIScrollView

- (void)setTabularSubviews:(NSArray *)tabularSubviews;

@property (nonatomic) TabularScrollViewOrientation orientation;

@property (nonatomic) CGFloat minSubviewHeight;

@end

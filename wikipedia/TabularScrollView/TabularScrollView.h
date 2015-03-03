//  Created by Monte Hurd on 3/17/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef enum {
    TABULAR_SCROLLVIEW_LAYOUT_VERTICAL   = 0,
    TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL = 1
} TabularScrollViewOrientation;

@interface TabularScrollView : UIScrollView

- (void)setTabularSubviews:(NSArray*)tabularSubviews;

@property (nonatomic) TabularScrollViewOrientation orientation;

@property (nonatomic) CGFloat minSubviewHeight;

@end

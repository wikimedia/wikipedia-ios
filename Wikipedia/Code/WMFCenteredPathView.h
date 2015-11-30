//  Created by Monte Hurd on 8/26/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

// Draws a CGPath scaled to fix exactly within the view.

#import <UIKit/UIKit.h>

@interface WMFCenteredPathView : UIView

- (id)initWithPath:(CGPathRef)newPath
       strokeWidth:(CGFloat)strokeWidth
       strokeColor:(UIColor*)strokeColor
         fillColor:(UIColor*)fillColor;

@end

//  Created by Monte Hurd on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIButton+ColorMask.h"
#import "UIImage+ColorMask.h"

@implementation UIButton (ColorMask)

- (void)maskButtonImageWithColor:(UIColor*)maskColor {
    UIImage* buttonImage = self.imageView.image;
    // Generate colored button image on background thread.
    __block UIImage* filteredImage = nil;
    // Since this needs to be synchronous, make it a high priority.
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        filteredImage = [buttonImage getImageOfColor:maskColor.CGColor];
    });
    [self setImage:filteredImage forState:UIControlStateNormal];
    [self setImage:filteredImage forState:UIControlStateSelected];
    [self setImage:filteredImage forState:UIControlStateHighlighted];
    [self setNeedsDisplay];
}

@end

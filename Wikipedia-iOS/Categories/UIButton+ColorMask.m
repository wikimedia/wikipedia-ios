//  Created by Monte Hurd on 2/14/14.

#import "UIButton+ColorMask.h"
#import "UIImage+ColorMask.h"

@implementation UIButton (ColorMask)

-(void)maskButtonImageWithColor:(UIColor *)maskColor
{
    UIImage *buttonImage = self.imageView.image;
    // Generate colored button image on a background q.
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        UIImage *filteredImage = [buttonImage getImageOfColor:maskColor.CGColor];
        dispatch_sync(dispatch_get_main_queue(), ^{
            // Update ui element on main thread.
            [self setImage:filteredImage forState:UIControlStateNormal];
            [self setNeedsDisplay];
        });
    });
}

@end

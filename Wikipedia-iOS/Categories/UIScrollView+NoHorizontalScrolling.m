//  Created by Monte Hurd on 4/2/14.

#import "UIScrollView+NoHorizontalScrolling.h"

@implementation UIScrollView (NoHorizontalScrolling)

-(void)preventHorizontalScrolling
{
    CGSize widthRestrictedContentSize = CGSizeMake(self.superview.frame.size.width, self.contentSize.height);
    if(!CGSizeEqualToSize(self.contentSize, widthRestrictedContentSize)){
        [self setContentSize: widthRestrictedContentSize];
    }
}

@end

//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+StatusBarHeight.h"

@implementation UIViewController (StatusBarHeight)

-(CGFloat)getStatusBarHeight
{
    CGSize size = [UIApplication sharedApplication].statusBarFrame.size;
    CGFloat val = MIN(size.width, size.height);
    return val;
}

@end

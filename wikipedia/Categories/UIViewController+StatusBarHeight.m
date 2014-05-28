//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+StatusBarHeight.h"

@implementation UIViewController (StatusBarHeight)

-(CGFloat)getStatusBarHeight
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    return MIN(statusBarFrame.size.height, statusBarFrame.size.width);
}

@end

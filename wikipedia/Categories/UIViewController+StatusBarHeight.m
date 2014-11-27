//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+StatusBarHeight.h"

@implementation UIViewController (StatusBarHeight)

-(CGFloat)getStatusBarHeight
{
    /*
    CGSize size = [UIApplication sharedApplication].statusBarFrame.size;
    CGFloat val = MIN(size.width, size.height);
    return val;
    */
    
    // ^ The determination above causes the top menu to not render correctly when in-call
    // status bar is active (shown with simulator via "Hardware->Toggle In-Call Status Bar")
    return 20;
}

@end

//  Created by Monte Hurd on 8/7/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIButton (WMFMultiLineHeight)

/**
 *  UIButtons displaying multiple lines of text don't seem to change their intrinsic
 *  content size reflect their multi-line height.
 *
 *  @return Height that accounts for multiple line button text.
 */
- (CGFloat)wmf_heightAccountingForMultiLineText;

@end

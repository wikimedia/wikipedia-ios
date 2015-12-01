//  Created by Monte Hurd on 9/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIView (ConstraintsScale)

- (void)adjustConstraintsFor:(NSLayoutAttribute)firstAttribute byMultiplier:(CGFloat)multiplier;

@end

//  Created by Monte Hurd on 9/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSObject+ConstraintsScale.h"
#import "UIView+ConstraintsScale.h"
#import "Defines.h"

@implementation NSObject (ConstraintsScale)

- (void)adjustConstraintsScaleForViews:(NSArray*)views {
    for (UIView* view in views) {
        [view adjustConstraintsFor:NSLayoutAttributeTop byMultiplier:MENUS_SCALE_MULTIPLIER];
        [view adjustConstraintsFor:NSLayoutAttributeBottom byMultiplier:MENUS_SCALE_MULTIPLIER];
        [view adjustConstraintsFor:NSLayoutAttributeLeading byMultiplier:MENUS_SCALE_MULTIPLIER];
        [view adjustConstraintsFor:NSLayoutAttributeTrailing byMultiplier:MENUS_SCALE_MULTIPLIER];
        [view adjustConstraintsFor:NSLayoutAttributeWidth byMultiplier:MENUS_SCALE_MULTIPLIER];
        [view adjustConstraintsFor:NSLayoutAttributeHeight byMultiplier:MENUS_SCALE_MULTIPLIER];
    }
}

@end

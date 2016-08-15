#import "NSObject+ConstraintsScale.h"
#import "UIView+ConstraintsScale.h"
#import "Defines.h"

@implementation NSObject (ConstraintsScale)

- (void)adjustConstraintsScaleForViews:(NSArray *)views {
  for (UIView *view in views) {
    [view adjustConstraintsFor:NSLayoutAttributeTop
                  byMultiplier:MENUS_SCALE_MULTIPLIER];
    [view adjustConstraintsFor:NSLayoutAttributeBottom
                  byMultiplier:MENUS_SCALE_MULTIPLIER];
    [view adjustConstraintsFor:NSLayoutAttributeLeading
                  byMultiplier:MENUS_SCALE_MULTIPLIER];
    [view adjustConstraintsFor:NSLayoutAttributeTrailing
                  byMultiplier:MENUS_SCALE_MULTIPLIER];
    [view adjustConstraintsFor:NSLayoutAttributeWidth
                  byMultiplier:MENUS_SCALE_MULTIPLIER];
    [view adjustConstraintsFor:NSLayoutAttributeHeight
                  byMultiplier:MENUS_SCALE_MULTIPLIER];
  }
}

@end

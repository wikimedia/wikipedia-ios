#import "UIView+RemoveConstraints.h"

@implementation UIView (RemoveConstraints)

- (void)removeConstraintsOfViewFromView:(UIView *)view {
    for (NSLayoutConstraint *c in view.constraints.copy) {
        if (c.firstItem == self || c.secondItem == self) {
            [view removeConstraint:c];
        }
    }
}

@end

#import "UIToolbar+WMFStyling.h"
#import "Wikipedia-Swift.h"

@implementation UIToolbar (WMFStyling)

- (void)wmf_applySolidWhiteBackgroundWithTopShadow {
    // HAX: Use a solid white background image instead of setting "translucency = no" because doing so causes a bug which increases the toolbar height and creates a ~200px gap between the top of the toolbar and the bottom of the view above it. Very strange.
    [self setBackgroundImage:[UIImage imageNamed:@"white-patch"]
          forToolbarPosition:UIBarPositionBottom
                  barMetrics:UIBarMetricsDefault];
    self.shadowColor = [UIColor colorWithWhite:0 alpha:0.08];
    self.shadowOffset = CGSizeMake(0.0, -1.0);
    self.shadowRadius = 1.0f;
    self.shadowOpacity = 1.0f;
}

@end

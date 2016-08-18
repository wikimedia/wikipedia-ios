#import <UIKit/UIKit.h>

@interface UILabel (WMFStyling)

/// Scale the receiver's current font size by the `MENUS_SCALE_MULTIPLIER`.
- (void)wmf_applyMenuScaleMultiplier;

- (void)wmf_applyDropShadow;

@end

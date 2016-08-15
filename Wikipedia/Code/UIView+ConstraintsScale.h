#import <UIKit/UIKit.h>

@interface UIView (ConstraintsScale)

- (void)adjustConstraintsFor:(NSLayoutAttribute)firstAttribute
                byMultiplier:(CGFloat)multiplier;

@end

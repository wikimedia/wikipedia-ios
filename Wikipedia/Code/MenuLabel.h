@import UIKit;

#import "PaddedLabel.h"

@interface MenuLabel : PaddedLabel

- (instancetype)initWithText:(NSString *)text
                    fontSize:(CGFloat)size
                        bold:(BOOL)bold
                       color:(UIColor *)color
                     padding:(UIEdgeInsets)padding;

@property (strong, nonatomic) UIColor *color;

@end

#import "UINavigationBar+WMFTransparency.h"

@implementation UINavigationBar (WMFTransparency)

- (void)wmf_makeTransparent {
    self.translucent = YES;
    self.shadowImage = [UIImage new];
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.backgroundColor = [UIColor clearColor];
}

@end

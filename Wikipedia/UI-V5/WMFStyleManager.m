
#import "WMFStyleManager.h"

static WMFStyleManager* _styleManager = nil;

@implementation WMFStyleManager

+ (void)setSharedStyleManager:(WMFStyleManager*)styleManger {
    _styleManager = styleManger;
}

- (void)applyStyleToWindow:(UIWindow*)window {
    window.backgroundColor = [UIColor whiteColor];
    [[UIButton appearance] setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [[UIButton appearance] setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal];
    [[UIButton appearance] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
}

@end


@implementation UIViewController (WMFStyleManager)

- (WMFStyleManager*)wmf_styleManager {
    return _styleManager;
}

@end

@implementation UIView (WMFStyleManager)

- (WMFStyleManager*)wmf_styleManager {
    return _styleManager;
}

@end


#import <Foundation/Foundation.h>

@interface WMFStyleManager : NSObject

+ (void)setSharedStyleManager:(WMFStyleManager*)styleManger;

- (void)applyStyleToWindow:(UIWindow*)window;

@end

@interface UIViewController (WMFStyleManager)

- (WMFStyleManager*)wmf_styleManager;

@end

@interface UIView (WMFStyleManager)

- (WMFStyleManager*)wmf_styleManager;

@end

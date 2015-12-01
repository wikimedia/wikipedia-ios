
#import <UIKit/UIKit.h>

@interface UITabBarController (WMFExtensions)

- (void)wmf_setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(dispatch_block_t)completion;

@property (nonatomic, assign, readonly) BOOL wmf_tabBarIsVisible;

@end

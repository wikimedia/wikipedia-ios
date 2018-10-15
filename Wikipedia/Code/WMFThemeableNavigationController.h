#import <UIKit/UIKit.h>
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@interface WMFThemeableNavigationController : UINavigationController <WMFThemeable>

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme;

@end

NS_ASSUME_NONNULL_END

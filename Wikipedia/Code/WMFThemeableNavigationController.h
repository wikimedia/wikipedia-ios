#import <UIKit/UIKit.h>
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@interface WMFThemeableNavigationController : UINavigationController <WMFThemeable>

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme isEditorStyle:(BOOL)isEditorStyle;

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme;

- (void)showSplashView;
- (void)hideSplashViewAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

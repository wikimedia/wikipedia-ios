#import <UIKit/UIKit.h>
@import WMF;
@class WMFThemeableNavigationController;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFThemeableNavigationControllerDelegate
- (void)themeableNavigationControllerTraitCollectionDidChange:(WMFThemeableNavigationController *)navigationController;
@end

@interface WMFThemeableNavigationController : UINavigationController <WMFThemeable>

@property (weak, nonatomic, nullable) NSObject<WMFThemeableNavigationControllerDelegate> *themeableNavigationControllerDelegate;

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme isEditorStyle:(BOOL)isEditorStyle;

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme;

- (void)showSplashView;
- (void)showSplashViewIfNotShowing;
- (void)hideSplashViewAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

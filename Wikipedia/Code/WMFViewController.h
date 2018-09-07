#import <UIKit/UIKit.h>
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@class WMFNavigationBar;

/*!
 @class        WMFViewController
 @abstract     Top level view controller that handles themeing and the navigation bar.
 @discussion   In Swift, use the equivalent Swift class ViewController. Due to the use of Swift classes Themeable and NavigationBar, it was easier to duplicate the implementation then try to have a shared Obj-C base class.
 */
@interface WMFViewController : UIViewController <WMFThemeable, WMFNavigationBarHiderDelegate>

@property (nonatomic, strong) WMFTheme *theme;

@property (nonatomic, readonly) BOOL showsNavigationBar;

@property (nonatomic, readwrite, getter=isSubtractingTopAndBottomSafeAreaInsetsFromScrollIndicatorInsets) BOOL subtractTopAndBottomSafeAreaInsetsFromScrollIndicatorInsets; // WKWebView workaround

@property (nonatomic, strong, readonly) WMFNavigationBar *navigationBar;

@property (nonatomic, strong, readonly) WMFNavigationBarHider *navigationBarHider;

@property (nonatomic, readonly, nullable) UIScrollView *scrollView; // Override to provide the scroll view for inset adjustment

- (void)scrollViewInsetsDidChange;

- (void)scrollToTop;

@end

NS_ASSUME_NONNULL_END

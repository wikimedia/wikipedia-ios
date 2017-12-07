#import <UIKit/UIKit.h>
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@class WMFNavigationBar;

/*!
 @class        WMFViewController
 @abstract     Top level view controller that handles themeing and the navigation bar.
 @discussion   In Swift, use the equivalent Swift class ViewController. Due to the use of Swift classes Themeable and NavigationBar, it was easier to duplicate the implementation then try to have a single Obj-C base class.
 */
@interface WMFViewController : UIViewController <WMFThemeable>

@property (nonatomic, strong) WMFTheme *theme;

@property (nonatomic, readonly) BOOL showsNavigationBar;
@property (nonatomic, strong, readonly) WMFNavigationBar *navigationBar;

@property (nonatomic, readonly, nullable) UIScrollView *scrollView; // Override to provide the scroll view for inset adjustment

- (void)didUpdateScrollViewInsets;

@end

NS_ASSUME_NONNULL_END

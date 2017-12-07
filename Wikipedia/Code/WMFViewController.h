#import <UIKit/UIKit.h>
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@class WMFNavigationBar;

@interface WMFViewController : UIViewController <WMFThemeable>

@property (nonatomic, strong) WMFTheme *theme;

@property (nonatomic, readonly) BOOL showsNavigationBar;
@property (nonatomic, strong, readonly) WMFNavigationBar *navigationBar;

@property (nonatomic, readonly, nullable) UIScrollView *scrollView; // Override to provide the scroll view for inset adjustment

- (void)didUpdateScrollViewInsets;

@end

NS_ASSUME_NONNULL_END


@import UIKit;

@protocol WMFPreviewControllerDelegate;

@interface WMFPreviewController : NSObject

- (instancetype)initWithPreviewViewController:(UIViewController*)previewViewController presentingViewController:(UIViewController<WMFPreviewControllerDelegate>*)presentingController tabBarController:(UITabBarController*)tabBarController;

@property (nonatomic, strong, readonly) UIViewController* previewViewController;
@property (nonatomic, strong, readonly) UIViewController* presentingViewController;
@property (nonatomic, strong, readonly) UITabBarController* tabBarController;

@property (nonatomic, assign) id<WMFPreviewControllerDelegate> delegate;


/**
 *  Controls how much of `presentedViewController` is vertically "popped up" when the transition begins.
 *
 *  Default is 300.0
 */
@property (nonatomic, assign) CGFloat previewHeight;


/**
 *  Presents the preview
 *
 *  @param animated Set YES to present with animation
 */
- (void)presentPreviewAnimated:(BOOL)animated;

@end


@protocol WMFPreviewControllerDelegate <NSObject>

- (void)previewController:(WMFPreviewController*)previewController didPresentViewController:(UIViewController*)viewController;
- (void)previewController:(WMFPreviewController*)previewController didDismissViewController:(UIViewController*)viewController;

@end

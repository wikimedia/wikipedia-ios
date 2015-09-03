
@import UIKit;

@protocol WMFPreviewControllerDelegate;

@interface WMFPreviewController : NSObject

/**
 *  Init a Preview Controller which will display a view controller as a pop up that can be dragged to present or dismiss
 *  This object uses view containment and simple animations to present the previewViewController's view
 *  The view and is removed from the hierarchy on completion
 *  It is the callers (delegates) responsibility to actually present the view controller in the "real" container.
 *  In general, you should do this without animation so it appears seemless.
 *  This class was created because doing this using standard transition APIs created problems with animations
 *
 *  @param previewViewController    The viewcontroller to preview
 *  @param containingViewController The view controller to use as the container (the preview will be added using view containment)
 *  @param tabBarController         The tab bar (if any), that needs animated out of the way for the preview to be visible
 *
 *  @return The Preview Controller
 */
- (instancetype)initWithPreviewViewController:(UIViewController*)previewViewController containingViewController:(UIViewController*)containingViewController tabBarController:(UITabBarController*)tabBarController;

@property (nonatomic, strong, readonly) UIViewController* previewViewController;
@property (nonatomic, weak, readonly) UIViewController* containingViewController;
@property (nonatomic, weak, readonly) UITabBarController* tabBarController;

/**
 *  Set to be notified when the preview is presented or dismissed
 */
@property (nonatomic, assign) id<WMFPreviewControllerDelegate> delegate;

/**
 *  Presents the preview
 *
 *  @param animated Set YES to present with animation
 */
- (void)presentPreviewAnimated:(BOOL)animated;


/**
 *  Update the preview baecause the size of the containingViewController changed.
 *  You are expected to call this method from inside of the animation block for [id<UIViewControllerTransitionCoordinator> animateAlongsideTransition:completion:]
 *
 *  @param newSize the new size of the containingViewController
 */
- (void)updatePreviewWithSizeChange:(CGSize)newSize;

@end


@protocol WMFPreviewControllerDelegate <NSObject>

/**
 *  Called when the preview is pulled to the top.
 *  At this point it wold be appropriate to display the vview controller in the hierarchy
 */
- (void)previewController:(WMFPreviewController*)previewController didPresentViewController:(UIViewController*)viewController;

/**
 *  Called if the preview is dismissed
 *  At this point it wold be appropriate to return to the view state before the preview began
 */
- (void)previewController:(WMFPreviewController*)previewController didDismissViewController:(UIViewController*)viewController;

@end

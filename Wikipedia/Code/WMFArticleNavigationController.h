#import "WMFRotationRespectingNavigationController.h"

@interface WMFArticleNavigationController : WMFRotationRespectingNavigationController

@property(nonatomic, readonly, getter=isSecondToolbarHidden) BOOL secondToolbarHidden;
- (void)setSecondToolbarHidden:(BOOL)secondToolbarHidden animated:(BOOL)animated;

@end

@interface UIViewController (UINavigationControllerContextualSecondToolbarItems)

@property(nullable, nonatomic, strong) NSArray<__kindof UIBarButtonItem *> *secondToolbarItems;

@end

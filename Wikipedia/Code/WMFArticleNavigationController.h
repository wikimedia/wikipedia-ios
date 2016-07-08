#import "WMFRotationRespectingNavigationController.h"

@interface WMFArticleNavigationController : WMFRotationRespectingNavigationController

@end


@interface UIViewController (UINavigationControllerContextualSecondToolbarItems)

@property (nullable, nonatomic, strong) NSArray<__kindof UIBarButtonItem *> *secondToolbarItems;

@end

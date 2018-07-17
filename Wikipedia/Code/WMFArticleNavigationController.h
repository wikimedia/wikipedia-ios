#import "WMFThemeableNavigationController.h"

@interface WMFArticleNavigationController : WMFThemeableNavigationController

@property (nonatomic, readonly, getter=isSecondToolbarHidden) BOOL secondToolbarHidden;
- (void)setSecondToolbarHidden:(BOOL)secondToolbarHidden animated:(BOOL)animated;
@property (nonatomic) CGFloat readingListHintHeight;
@property (nonatomic) BOOL readingListHintHidden;

@end

@interface UIViewController (UINavigationControllerContextualSecondToolbarItems)

@property (nullable, nonatomic, strong) NSArray<__kindof UIBarButtonItem *> *secondToolbarItems;

@end

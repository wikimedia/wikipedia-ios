#import "WMFArticleViewController.h"

@class MWKDataStore;
@class WMFTableOfContentsViewController;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (WMFArticlePresentation)

- (void)wmf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

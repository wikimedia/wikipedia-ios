#import "WMFArticleViewController.h"

@class MWKDataStore;
@class WMFTableOfContentsViewController;
@class WMFSession;
@class WMFAlertManager;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated;

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated completion:(nullable void (^)(WMFArticleViewController *_Nullable))completion;

- (void)wmf_checkAndPushPotentialArticleWithURL:(NSURL *)maybeArticleURL usingSession:(WMFSession *)session alertManager:(WMFAlertManager *)alertManager dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated completion:(nullable void (^)(WMFArticleViewController *_Nullable))completion;

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme animated:(BOOL)animated;

- (void)wmf_pushArticleViewController:(WMFArticleViewController *)viewController animated:(BOOL)animated;

- (void)wmf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

#import "WMFArticleViewController.h"

@class MWKDataStore;
@class WMFTableOfContentsViewController;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (WMFArticlePresentation)

- (WMFArticleViewController *)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated;

- (WMFArticleViewController *)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated articleLoadCompletion:(dispatch_block_t)articleLoadCompletion;

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme animated:(BOOL)animated;

- (void)wmf_pushArticleViewController:(WMFArticleViewController *)viewController animated:(BOOL)animated;

- (void)wmf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

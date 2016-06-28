
#import <UIKit/UIKit.h>
#import "WMFArticleViewController.h"

@class MWKTitle, MWKDataStore;
@class WMFTableOfContentsViewController;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated;

- (void)wmf_pushArticleWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore animated:(BOOL)animated;

- (void)wmf_pushArticleViewController:(WMFArticleViewController*)viewController animated:(BOOL)animated;

@end


NS_ASSUME_NONNULL_END
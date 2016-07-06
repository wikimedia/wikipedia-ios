#import "WMFArticleViewController.h"

@class WMFRandomArticleFetcher;
@class MWKSite;
@class MWKDataStore;

@interface WMFRandomArticleViewController : WMFArticleViewController

- (instancetype)initWithArticleTitle:(nullable MWKTitle*)title randomArticleFetcher:(nonnull WMFRandomArticleFetcher*)randomArticleFetcher site:(nonnull MWKSite*)site dataStore:(nonnull MWKDataStore*)dataStore;


@end
